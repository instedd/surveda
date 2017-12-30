defmodule Ask.NumberTranslator.Macros do
  defmacro generate_map() do
    File.ls!("#{__DIR__}/numbers")
    |> Enum.map(fn filename ->
      filename = filename |> Path.basename(".json")

      data = Poison.decode!(File.read!("#{__DIR__}/numbers/#{filename}.json"))
      data = {:%{}, [], data |> Enum.to_list}

      quote do
        @external_resource Path.join([__DIR__, "numbers/#{unquote(filename)}.json"])
        def map(unquote(filename)), do: unquote(data)
      end
    end)
  end

  defmacro generate_langs() do
    {:ok, filenames} = File.ls(Path.join([__DIR__, "numbers"]))
      languages = filenames |> Enum.map(fn filename ->
        String.replace(filename, ".json", "")
      end)
    quote do
      @external_resource Path.join([__DIR__, "numbers"])

      def langs(), do: unquote(languages)
    end
  end
end

defmodule Ask.NumberTranslator do
  @spec match(lang :: String.t, srt :: String.t) :: {:ok, integer} | :not_found
  def match(lang, str) do
    table = map(lang)

    case table[str] do
      nil -> :not_found
      match -> {:ok, match}
    end
  end

  require Ask.NumberTranslator.Macros
  Ask.NumberTranslator.Macros.generate_map
  Ask.NumberTranslator.Macros.generate_langs
  def map(_), do: %{}

  def try_parse(string, language) do
    cond do
      map(language)[string] -> map(language)[string]
      true -> compare_string(string, language)
    end
  end

  def compare_string(string, language) do
    current_language_list = map(language)

    input_length = String.length(string)

    {min_levenshtein, min_values} = Enum.reduce(current_language_list, {input_length, []}, fn({key, number}, min) ->
      new_levenshtein = Simetric.Levenshtein.compare(key, string)
      {current_min, current_numbers} = min

      cond do
        new_levenshtein < current_min -> {new_levenshtein, [number]}
        new_levenshtein == current_min -> {new_levenshtein, [number | current_numbers]}
        true -> min
      end
    end)

    if min_levenshtein <= Float.ceil(input_length / 5.0) && has_unique_value(min_values) do
      Enum.at(min_values, 0)
    else
      false
    end
  end

  def has_unique_value([head | tail]) do
    compare_list(tail, head)
  end

  defp compare_list([head | tail], value) do
    (head == value) && compare_list(tail, value)
  end

  defp compare_list([], _) do
    true
  end

end
