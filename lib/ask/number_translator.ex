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
end

defmodule Ask.NumberTranslator do
  @spec match(lang :: String.t, srt :: String.t) :: {:ok, integer} | :not_found
  def match(lang, str) do
    table = map(lang)

    case table[str] do
      nil -> :not_found
        #
      match -> {:ok, match}
    end
  end

  require Ask.NumberTranslator.Macros
  Ask.NumberTranslator.Macros.generate_map
  def map(_), do: %{}


  def check_if_string_is_number(string, language) do
    compare_string(string, language)
    cond do
      map(language)[string] -> map(language)[string]
      true -> compare_string(string, language)
    end
  end

  def compare_string(string, language) do
    array = map(language)
    {min_key, min_value} = Enum.min_by(array, fn({key, _}) ->
      Simetric.Levenshtein.compare(key, string)
    end)
    if Simetric.Levenshtein.compare(min_key, string)/ String.length(string) <= 0.2 do
      min_value
    else
      nil
    end
  end

end
