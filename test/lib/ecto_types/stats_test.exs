defmodule Ask.StatsTest do
  use Ask.ModelCase
  alias Ask.Stats

  describe "dump:" do
    test "should dump empty" do
      assert {:ok, "{\"total_sent_sms\":0,\"total_received_sms\":0,\"total_call_time_seconds\":null,\"total_call_time\":null}"} == Stats.dump(%Stats{})
    end

    test "should dump full" do
      assert {:ok, "{\"total_sent_sms\":3,\"total_received_sms\":2,\"total_call_time_seconds\":60,\"total_call_time\":1}"} == Stats.dump(%Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time_seconds: 60, total_call_time: 1})
    end
  end

  describe "load:" do
    test "should load empty" do
      assert {:ok, %Stats{total_received_sms: nil, total_sent_sms: nil, total_call_time: nil, total_call_time_seconds: nil}} == Stats.load("{}")
    end

    test "should load full" do
      assert {:ok, %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 1, total_call_time_seconds: 60}} == Stats.load("{\"total_sent_sms\":3,\"total_received_sms\":2,\"total_call_time\":1,\"total_call_time_seconds\":60}")
    end
  end

  describe "cast:" do
    test "shuld cast to itself" do
      assert {:ok, %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 1, total_call_time_seconds: 60}} == Stats.cast(%Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 1, total_call_time_seconds: 60})
    end

    test "shuld cast nil" do
      assert {:ok, %Stats{}} == Stats.cast(nil)
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

  describe "call time:" do
    test "sets total_call_time_seconds" do
      stats = %Stats{} |> Stats.total_call_time_seconds(12)

      assert Stats.total_call_time_seconds(stats) == 12
    end

    test "total_call_time backward compatibility" do
      stats = %Stats{total_call_time: 1.5}

      assert Stats.total_call_time_seconds(stats) == 90
    end

    test "resolves to new field in discrepancy" do
      stats = %Stats{total_call_time: 1.5, total_call_time_seconds: 30}

      assert Stats.total_call_time_seconds(stats) == 30
    end

    test "defaults old total_call_time to zero" do
      {:ok, stats} = Stats.load("{}")

      assert Stats.total_call_time_seconds(stats) == 0
    end

    test "display total_call_time in minutes and seconds" do
      stats = %Stats{total_call_time: 1.5}

      assert Stats.total_call_time(stats) == "1m 30s"
    end
  end

end
