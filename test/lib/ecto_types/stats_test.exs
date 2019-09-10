defmodule Ask.StatsTest do
  use Ask.ModelCase
  alias Ask.Stats

  describe "dump:" do
    test "should dump empty" do
      assert {:ok, "{\"total_sent_sms\":0,\"total_received_sms\":0}"} == Stats.dump(%Stats{})
    end

    test "should dump full" do
      assert {:ok, "{\"total_sent_sms\":3,\"total_received_sms\":2}"} == Stats.dump(%Stats{total_received_sms: 2, total_sent_sms: 3})
    end
  end

  describe "load:" do
    test "should load empty" do
      assert {:ok, %Stats{total_received_sms: 0, total_sent_sms: 0}} == Stats.load("{\"total_sent_sms\":0,\"total_received_sms\":0}")
    end

    test "should load full" do
      assert {:ok, %Stats{total_received_sms: 2, total_sent_sms: 3}} == Stats.load("{\"total_sent_sms\":3,\"total_received_sms\":2}")
    end
  end

  describe "cast:" do
    test "shuld cast to itself" do
      assert {:ok, %Stats{total_received_sms: 2, total_sent_sms: 3}} == Stats.cast(%Stats{total_received_sms: 2, total_sent_sms: 3})
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
end
