defmodule Ask.Runtime.ChannelPatterns do
  def matching_patterns(patterns, sanitized_number_as_list) do
    Enum.filter patterns, fn(pattern) ->
      pattern_as_list = Map.get(pattern, "input")
        |> sanitize_pattern
        |> String.graphemes
      if (pattern_as_list |> Enum.count) == (sanitized_number_as_list |> Enum.count) do
        pattern_matches(pattern_as_list, sanitized_number_as_list)
      else
        false
      end
    end
  end

  defp pattern_matches([], []) do
    true
  end

  defp pattern_matches([p | pattern], [d | number]) do
    case p do
      "X" -> pattern_matches(pattern, number)
      digit -> (digit == d) && pattern_matches(pattern, number)
    end
  end

  defp sanitize_pattern(p) do
     ~r/[^\dX]/ |> Regex.replace(p, "")
  end

  def apply_pattern(pattern, sanitized_number_as_list) do
    xs = xs_values(Map.get(pattern, "input") |> sanitize_pattern |> String.graphemes, sanitized_number_as_list)

    Map.get(pattern, "output")
      |> sanitize_pattern
      |> String.graphemes
      |> apply_output_pattern(xs)
      |> Enum.join("")
  end

  defp xs_values([d | pattern], [d | number]) do
    xs_values(pattern, number)
  end

  defp xs_values(["X" | pattern], [d | number]) do
    [d | xs_values(pattern, number)]
  end

  defp xs_values([], []) do
    []
  end

  defp apply_output_pattern(["X" | pattern], [x | xs]) do
    [x | apply_output_pattern(pattern, xs)]
  end

  defp apply_output_pattern([d | pattern], xs) do
    [d | apply_output_pattern(pattern, xs)]
  end

  defp apply_output_pattern([], _) do
    []
  end
end
