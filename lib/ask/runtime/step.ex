defmodule Ask.Runtime.Step do
  alias Ask.Questionnaire

  def is_in_numeric_range(step, value) do
    min_value = step["min_value"]
    max_value = step["max_value"]
    !((min_value && value < min_value) || (max_value && value > max_value))
  end

  def has_refusal_option(%{"refusal" => refusal = %{"enabled" => true}}, reply, mode, language, default_language) do
    fetch(:response, refusal, mode, language, default_language)
    |> Enum.any?(fn r -> (r |> clean_string) == reply end)
  end
  def has_refusal_option(_, _, _, _, _), do: false

  def validate(step, reply, mode, language, default_language) do
    reply = reply |> clean_string

    case step["type"] do
      "multiple-choice" ->
        choice = step["choices"]
        |> Enum.find(fn choice ->
          fetch(:response, choice, mode, language, default_language) |> Enum.any?(fn r -> (r |> clean_string) == reply end)
        end)
        if (choice), do: choice["value"], else: :invalid_answer
      "numeric" ->
        num = is_numeric(reply)
        if (num && is_in_numeric_range(step, num)) || has_refusal_option(step, reply, mode, language, default_language) do
          reply
        else
          :invalid_answer
        end
      "language-selection" ->
        choices = step["language_choices"]
        {num, ""} = Integer.parse(reply)
        (choices |> Enum.at(num)) || (choices |> Enum.at(1))
      "disposition" -> nil
      "explanation" -> nil
    end
  end

  def skip_logic(step, reply) do
    case step["type"] do
      "numeric" ->
        if is_numeric(reply) do
          value = String.to_integer(reply)
          step["ranges"]
          |> Enum.find_value(nil, fn (range) ->
            if (range["from"] == nil || range["from"] <= value) && (range["to"]
              == nil || range["to"] >= value), do: range["skip_logic"], else: false
          end)
        else
          step["refusal"]["skip_logic"]
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

  def fetch(key, step, mode, language, default_language) do
    # If a key is missing in a language, try with the default one as a replacement
    fetch(key, step, mode, language) ||
      fetch(key, step, mode, default_language)
  end

  defp fetch(:prompt, step = %{"type" => "language-selection"}, mode, _language) do
    step
    |> Map.get("prompt", %{})
    |> Map.get(mode)
    |> split_by_newlines(mode)
  end

  defp fetch(:prompt, step, mode, language) do
    step
    |> Map.get("prompt", %{})
    |> Map.get(language, %{})
    |> Map.get(mode)
    |> split_by_newlines(mode)
  end

  defp fetch(:response, step, mode, language) do
    case step
    |> Map.get("responses", %{})
    |> Map.get(mode, %{}) do
      response when is_map(response) ->
        response |> Map.get(language)
      response ->
        response
    end
  end

  defp fetch(:error_msg, error_msg_step, mode, language) do
    error_msg_step
    |> Map.get(language, %{})
    |> Map.get(mode)
    |> split_by_newlines(mode)
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
