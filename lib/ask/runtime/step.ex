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
        num = is_numeric(reply)
        cond do
          is_refusal_option(step, reply, mode, language) ->
            {:refusal, reply}
          num && is_in_numeric_range(step, num) ->
            reply
          :else ->
            :invalid_answer
        end
      "language-selection" ->
        if is_numeric(reply) do
          choices = step["language_choices"]
          {num, ""} = Integer.parse(reply)
          (choices |> Enum.at(num)) || (choices |> Enum.at(1))
        else
          :invalid_answer
        end
      "disposition" -> nil
      "explanation" -> nil
    end
  end

  def skip_logic(step, reply, mode, language) do
    case step["type"] do
      "numeric" ->
        if is_refusal_option(step, reply, mode, language) do
          step["refusal"]["skip_logic"]
        else
          value = String.to_integer(reply)
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
      "explanation" ->
        step["skip_logic"]
      "flag" ->
        step["skip_logic"]
      "language-selection" ->
        nil
    end
  end

  def fetch(:reply_step, step, mode, language) do
    ReplyStep.new(fetch(:prompt, step, mode, language), step["title"], step["id"])
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
        response |> Map.get(language)
      response ->
        response
    end
  end

  def fetch(:msg, msg, mode, language) do
    msg
    |> Map.get(language, %{})
    |> Map.get(mode)
    |> split_by_newlines(mode)
  end

  def fetch(:reply_msg, msg, mode, language, title) do
    ReplyStep.new(fetch(:msg, msg, mode, language), title)
  end

  defp split_by_newlines(text, mode) do
    if mode == "sms" && text do
      text |> String.split(Questionnaire.sms_split_separator)
    else
      [text]
    end
  end

  defp clean_string(nil), do: ""

  defp clean_string(string) do
    string |> String.trim |> String.downcase
  end

  defp is_numeric(str) do
    case Float.parse(str) do
      {num, ""} -> num
      {_num, _r} -> false               # _r : remainder_of_bianry
      :error     -> false
    end
  end
end
