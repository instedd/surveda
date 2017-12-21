defmodule Ask.Runtime.Step do
  alias Ask.Questionnaire
  alias Ask.Runtime.ReplyStep

  def is_in_numeric_range(step, value) do
    min_value = step["min_value"]
    max_value = step["max_value"]
    !((min_value && value < min_value) || (max_value && value > max_value))
  end

  def is_refusal_option(%{"refusal" => %{"enabled" => true} = refusal}, reply, mode, language) do
    fetch(:response, refusal, mode, language)
    |> Enum.any?(fn r -> (r |> clean_string) == reply end)
  end
  def is_refusal_option(_, _, _, _), do: false

  def validate(step, reply, mode, language) do
    reply = reply |> clean_string

    case step["type"] do
      "multiple-choice" ->
        choice = step["choices"]
        |> Enum.find(fn choice ->
          fetch(:response, choice, mode, language) |> Enum.any?(fn r -> (r |> clean_string) == reply end)
        end)
        if (choice), do: choice["value"], else: :invalid_answer
      "numeric" ->
        num = is_numeric_permissive(reply, language, step)
        cond do
          is_refusal_option(step, reply, mode, language) ->
            {:refusal, reply}
          num && is_in_numeric_range(step, num) ->
            to_string(num)
          :else ->
            :invalid_answer
        end
      "language-selection" ->
        if is_numeric(reply) do
          choices = step["language_choices"]
          {num, ""} = Integer.parse(reply)
          (choices |> Enum.at(num - 1)) || (choices |> Enum.at(0))
        else
          :invalid_answer
        end
      _ -> nil
    end
  end

  def skip_logic(step, reply, mode, language) do
    case step["type"] do
      "numeric" ->
        if is_refusal_option(step, reply, mode, language) do
          step["refusal"]["skip_logic"]
        else
          value = is_numeric_permissive(reply, language, step)
          step["ranges"]
          |> Enum.find_value(nil, fn (range) ->
            if (range["from"] == nil || range["from"] <= value) && (range["to"]
              == nil || range["to"] >= value), do: range["skip_logic"], else: false
          end)
        end
      "multiple-choice" ->
        step
        |> Map.get("choices")
        |> Enum.find(fn choice -> choice["value"] == reply end)
        |> Map.get("skip_logic")
      "explanation" -> step["skip_logic"]
      "flag" -> step["skip_logic"]
      _ -> nil
    end
  end

  def fetch(:reply_step, step, mode, language) do
    choices = case step["type"] do
      "multiple-choice" ->
        step["choices"]
        |> Enum.map(fn choice ->
          fetch(:response, choice, mode, language)
        end)
      "language-selection" ->
        step["language_choices"]
      _ -> []
    end

    refusal = fetch(:refusal, step, mode, language)
    num_digits = fetch(:num_digits, step, mode, language)

    ReplyStep.new(fetch(:prompt, step, mode, language), step["title"], step["type"], step["id"], choices, step["min_value"], step["max_value"], refusal, num_digits)
  end

  def fetch(:prompt, step = %{"type" => "language-selection"}, mode, _language) do
    step
    |> Map.get("prompt", %{})
    |> Map.get(mode)
    |> split_by_newlines(mode)
  end

  def fetch(:prompt, step, mode, language) do
    step
    |> Map.get("prompt", %{})
    |> Map.get(language, %{})
    |> Map.get(mode)
    |> split_by_newlines(mode)
  end

  def fetch(:response, step, mode, language) do
    case step
    |> Map.get("responses", %{})
    |> Map.get(mode, %{}) do
      response when is_map(response) ->
        response |> Map.get(language) |> to_list
      response ->
        response |> to_list
    end
  end

  def fetch(:msg, msg, mode, language) do
    msg
    |> Map.get(language, %{})
    |> Map.get(mode)
    |> split_by_newlines(mode)
  end

  def fetch(:refusal, step, "ivr", _language) do
    case step do
      %{"type" => "numeric", "refusal" => %{"enabled" => true, "responses" => %{"ivr" => value}}} ->
        value
      _ ->
        nil
    end
  end

  def fetch(:refusal, step, mode, language) do
    case step do
      %{"type" => "numeric", "refusal" => %{"enabled" => true, "responses" => %{^mode => %{^language => value}}}} ->
        value
      _ ->
        nil
    end
  end

  def fetch(:num_digits, step, "ivr", _language) do
    case step["type"] do
      "language-selection" ->
        # If we have 9 choices (1..9) then we can set numDigits to 1,
        # otherwise we can't (it's either 1 or 2 digits).
        choices = step["language_choices"]
        if length(choices) < 9 do
          1
        else
          nil
        end
      "multiple-choice" ->
        lengths = step["choices"]
        |> Enum.flat_map(&(&1["responses"]["ivr"]))
        |> Enum.flat_map(fn v -> v |> String.split(",") end)
        |> Enum.map(fn v -> v |> String.trim |> String.length end)
        |> Enum.uniq

        # Only send numDigits if all choices have the same length
        case lengths do
          [length] -> length
          _ -> nil
        end
      "numeric" ->
        # Only send numDigits if the min and max values have the same string length,
        # also taking into account the values of refusal responses
        refusal = step["refusal"]

        values = if refusal do
          refusal["responses"]["ivr"]
        else
          []
        end

        min_value = step["min_value"]
        max_value = step["max_value"]
        if min_value && max_value do
          values = [min_value, max_value | values]
          |> Enum.map(fn v -> v |> to_string |> String.length end)
          |> Enum.uniq

          if length(values) == 1 do
            hd(values)
          else
            nil
          end
        else
          nil
        end
      _ ->
        nil
    end
  end

  def fetch(:num_digits, _step, _mode, _language) do
    nil
  end

  def fetch(:reply_msg, msg, mode, language, title) do
    ReplyStep.new(fetch(:msg, msg, mode, language), title)
  end

  defp to_list(value) do
    if is_list(value) do
      value
    else
      [value]
    end
  end

  defp split_by_newlines(text, mode) do
    if mode == "sms" && text do
      split_by_newlines(text)
    else
      [text]
    end
  end

  def split_by_newlines(text) do
    text |> String.split(Questionnaire.sms_split_separator)
  end

  defp clean_string(nil), do: ""

  defp clean_string(string) do
    string |> String.trim |> String.downcase
  end

  defp is_numeric(str) do
    case Float.parse(str) do
      {num, ""}  -> num
      {_num, _r} -> false               # _r : remainder_of_bianry
      :error     -> false
    end
  end

  defp is_numeric_permissive(str, language, step) do
    case Float.parse(String.trim(str)) do
      {num, _} ->
        if round(num) == num do
          round(num)
        else
          num
        end
      :error -> Ask.NumberTranslator.try_parse(str, language)
    end
  end
end
