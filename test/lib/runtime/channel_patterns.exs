defmodule Ask.ChannelPatternsTest do
  use ExUnit.Case
  alias Ask.Runtime.ChannelPatterns

  test "matches sanitized phone number against input patterns" do
    canonical_phone_number = ["1", "2", "3", "4"]
    patterns = [
      %{"input" => "1XXX", "output" => "1XXX"}, #matches
      %{"input" => "X2XX", "output" => "1XXX"}, #matches
      %{"input" => "XX3X", "output" => "1XXX"}, #matches
      %{"input" => "XXX4", "output" => "1XXX"}, #matches
      %{"input" => "12XX", "output" => "1XXX"}, #matches
      %{"input" => "XX34", "output" => "1XXX"}, #matches
      %{"input" => "1XX4", "output" => "1XXX"}, #matches
      %{"input" => "5XXX", "output" => "1XXX"}, #doesn't match
      %{"input" => "X5XX", "output" => "1XXX"}, #doesn't match
      %{"input" => "XX5X", "output" => "1XXX"}, #doesn't match
      %{"input" => "XXX5", "output" => "1XXX"}, #doesn't match
      %{"input" => "XXXXX", "output" => "1XXX"}, #doesn't match
      %{"input" => "1234X", "output" => "1XXX"}, #doesn't match
      %{"input" => "X1234", "output" => "1XXX"} #doesn't match
    ]

    assert (ChannelPatterns.matching_patterns(patterns, canonical_phone_number) == [
      %{"input" => "1XXX", "output" => "1XXX"}, #matches
      %{"input" => "X2XX", "output" => "1XXX"}, #matches
      %{"input" => "XX3X", "output" => "1XXX"}, #matches
      %{"input" => "XXX4", "output" => "1XXX"}, #matches
      %{"input" => "12XX", "output" => "1XXX"}, #matches
      %{"input" => "XX34", "output" => "1XXX"}, #matches
      %{"input" => "1XX4", "output" => "1XXX"} #matches
    ])
  end

  test "matching against empty patterns returns empty list" do
    canonical_phone_number = ["1", "2", "3", "4"]
    assert ChannelPatterns.matching_patterns([], canonical_phone_number) == []
  end

  test "applies output pattern to sanitized phone number" do
    canonical_phone_number = ["1", "2", "3", "4"]
    patterns = [
      %{"input" => "XXXX", "output" => "555XXXX"},
      %{"input" => "XXXX", "output" => "XXXX555"},
      %{"input" => "XXXX", "output" => "7X9X5X3X0"}
    ]

    expected_canonical_phone_numbers = [
      "5551234",
      "1234555",
      "719253340"
    ]

    assert (patterns |> Enum.map(&(ChannelPatterns.apply_pattern(&1, canonical_phone_number)))) == expected_canonical_phone_numbers
  end
end
