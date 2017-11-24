defmodule Ask.StatsTest do
  use Ask.ModelCase
  alias Ask.Stats

  describe "dump:" do
    test "should dump empty" do
      assert {:ok, "{\"total_sent_sms\":0,\"total_received_sms\":0,\"total_call_time\":0,\"current_call_last_interaction_time\":null,\"current_call_first_interaction_time\":null}"} == Stats.dump(%Stats{})
    end

    test "should dump full" do
      now = DateTime.utc_now
      iso_now = now |> DateTime.to_iso8601

      assert {:ok, "{\"total_sent_sms\":3,\"total_received_sms\":2,\"total_call_time\":2,\"current_call_last_interaction_time\":\"#{iso_now}\",\"current_call_first_interaction_time\":\"#{iso_now}\"}"} == Stats.dump(%Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 2, current_call_first_interaction_time: now, current_call_last_interaction_time: now})
    end
  end

  describe "load:" do
    test "should load empty" do
      assert {:ok, %Stats{total_received_sms: 0, total_sent_sms: 0, total_call_time: 0, current_call_first_interaction_time: nil, current_call_last_interaction_time: nil}} == Stats.load("{\"total_sent_sms\":0,\"total_received_sms\":0,\"total_call_time\":0,\"current_call_last_interaction_time\":null,\"current_call_first_interaction_time\":null}")
    end

    test "should load full" do
      now = DateTime.utc_now
      iso_now = now |> DateTime.to_iso8601

      assert {:ok, %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 2, current_call_first_interaction_time: now, current_call_last_interaction_time: now}} == Stats.load("{\"total_sent_sms\":3,\"total_received_sms\":2,\"total_call_time\":2,\"current_call_last_interaction_time\":\"#{iso_now}\",\"current_call_first_interaction_time\":\"#{iso_now}\"}")
    end
  end

  describe "cast:" do
    test "shuld cast to itself" do
      now = DateTime.utc_now

      assert {:ok, %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 2, current_call_first_interaction_time: now, current_call_last_interaction_time: now}} == Stats.cast(%Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 2, current_call_first_interaction_time: now, current_call_last_interaction_time: now})
    end

    test "should cast string datetimes" do
      now = DateTime.utc_now
      iso_now = now |> DateTime.to_iso8601

      assert {
        :ok,
        %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 2, current_call_first_interaction_time: now, current_call_last_interaction_time: now}
      } == Stats.cast(%{total_received_sms: 2, total_sent_sms: 3, total_call_time: 2, current_call_first_interaction_time: iso_now, current_call_last_interaction_time: iso_now})
    end

    test "should cast string days with string keys" do
      now = DateTime.utc_now
      iso_now = now |> DateTime.to_iso8601

      assert {
        :ok,
        %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 2, current_call_first_interaction_time: now, current_call_last_interaction_time: now}
      } == Stats.cast(%{"total_received_sms" => 2, "total_sent_sms" => 3, "total_call_time" => 2, "current_call_first_interaction_time" => iso_now, "current_call_last_interaction_time" => iso_now})
    end

    test "shuld cast a struct with string keys" do
      now = DateTime.utc_now

      assert {
        :ok,
        %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 2, current_call_first_interaction_time: now, current_call_last_interaction_time: now}
      } == Stats.cast(%{"total_received_sms" => 2, "total_sent_sms" => 3, "total_call_time" => 2, "current_call_first_interaction_time" => now, "current_call_last_interaction_time" => now})
    end

    test "shuld cast nil" do
      assert {:ok, %Stats{}} == Stats.cast(nil)
    end
  end

  describe "call time:" do
    test "sets current_call_first_interaction_time if not available" do
      now = DateTime.utc_now

      stats = %Stats{} |> Stats.set_interaction_time(now)

      assert Stats.first_interaction_time(stats) == now
      assert Stats.last_interaction_time(stats) == nil
    end

    test "sets current_call_last_interaction_time if first is already set" do
      now = DateTime.utc_now
      ten_minutes_ago = now |> Timex.shift(minutes: -10)

      stats = %Stats{}
      |> Stats.first_interaction_time(ten_minutes_ago)
      |> Stats.set_interaction_time(now)

      assert Stats.first_interaction_time(stats) == ten_minutes_ago
      assert Stats.last_interaction_time(stats) == now
    end

    test "sets total_call_time and clears interaction times" do
      now = DateTime.utc_now
      ten_minutes_ago = now |> Timex.shift(minutes: -12)

      stats = %Stats{}
      |> Stats.first_interaction_time(ten_minutes_ago)
      |> Stats.last_interaction_time(now)
      |> Stats.add_total_call_time()

      assert Stats.first_interaction_time(stats) == nil
      assert Stats.last_interaction_time(stats) == nil
      assert Stats.total_call_time(stats) == 12
    end
  end

  describe "sms count:" do
    test "adds to received sms" do
      stats = %Stats{} |> Stats.add_received_sms()
      assert 1 == stats |> Stats.total_received_sms()

      stats = stats |> Stats.add_received_sms(3)
      assert 4 == stats |> Stats.total_received_sms()
    end

    test "adds to sent sms" do
      stats = %Stats{} |> Stats.add_sent_sms()
      assert 1 == stats |> Stats.total_sent_sms()

      stats = stats |> Stats.add_sent_sms(3)
      assert 4 == stats |> Stats.total_sent_sms()
    end
  end
end
