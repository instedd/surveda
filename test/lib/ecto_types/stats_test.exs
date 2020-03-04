defmodule Ask.StatsTest do
  use Ask.ModelCase
  alias Ask.Stats

  describe "dump:" do
    test "should dump empty" do
      assert {:ok, "{\"total_sent_sms\":0,\"total_received_sms\":0,\"total_call_time_seconds\":null,\"total_call_time\":null,\"last_call_started\":false,\"call_durations\":{},\"attempts\":null}"} == Stats.dump(%Stats{})
    end

    test "should dump full" do
      assert {:ok, "{\"total_sent_sms\":3,\"total_received_sms\":2,\"total_call_time_seconds\":60,\"total_call_time\":1,\"last_call_started\":true,\"call_durations\":{\"12345\":30},\"attempts\":{\"sms\":5,\"mobileweb\":7,\"ivr\":6}}"} == Stats.dump(%Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time_seconds: 60, total_call_time: 1, attempts: %{sms: 5, ivr: 6, mobileweb: 7}, last_call_started: true, call_durations: %{"12345" => 30}})
    end
  end

  describe "load:" do
    test "should load empty" do
      assert {:ok, %Stats{total_received_sms: nil, total_sent_sms: nil, total_call_time: nil, total_call_time_seconds: nil, attempts: nil, call_durations: %{}}} == Stats.load("{}")
    end

    test "should load full" do
      assert {:ok, %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 1, total_call_time_seconds: 60, attempts: %{"ivr" => 6, "sms" => 5, "mobileweb" => 7}, call_durations: %{"415" => 42, "some-call-id" => 32}}} == Stats.load("{\"total_sent_sms\":3,\"total_received_sms\":2,\"total_call_time\":1,\"total_call_time_seconds\":60,\"attempts\":{\"mobileweb\":7,\"sms\":5,\"ivr\":6},\"call_durations\":{\"415\":42,\"some-call-id\":32}}")
    end
  end

  describe "cast:" do
    test "shuld cast to itself" do
      assert {:ok, %Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 1, total_call_time_seconds: 60, attempts: %{sms: 5, ivr: 6, mobileweb: 7}}} == Stats.cast(%Stats{total_received_sms: 2, total_sent_sms: 3, total_call_time: 1, total_call_time_seconds: 60, attempts: %{sms: 5, ivr: 6, mobileweb: 7}})
    end

    test "shuld cast nil" do
      assert {:ok, %Stats{}} == Stats.cast(nil)
    end
  end

  describe "mode attempts" do
    test "adds sms" do
      stats = %Stats{}
      assert 0 == stats |> Stats.attempts(:sms)
      assert 0 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:sms)
      assert 1 == stats |> Stats.attempts(:sms)
      assert 1 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:sms)
      assert 2 == stats |> Stats.attempts(:sms)
      assert 2 == stats |> Stats.attempts(:all)

      assert 0 == stats |> Stats.attempts(:ivr)
      assert 0 == stats |> Stats.attempts(:mobileweb)
      assert 2 == stats |> Stats.attempts(:all)
    end

    test "adds ivr" do
      stats = %Stats{}
      assert 0 == stats |> Stats.attempts(:ivr)
      assert 0 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:ivr)
      assert 1 == stats.attempts["ivr"]
      assert 0 == stats |> Stats.attempts(:ivr)
      assert 0 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.with_last_call_attempted
      assert 1 == stats.attempts["ivr"]
      assert 1 == stats |> Stats.attempts(:ivr)
      assert 1 == stats |> Stats.attempts(:all)

      stats = stats
              |> Stats.add_attempt(:ivr)
              |> Stats.with_last_call_attempted
      assert 2 == stats.attempts["ivr"]
      assert 2 == stats |> Stats.attempts(:ivr)
      assert 2 == stats |> Stats.attempts(:all)

      assert 0 == stats |> Stats.attempts(:sms)
      assert 0 == stats |> Stats.attempts(:mobileweb)
      assert 2 == stats |> Stats.attempts(:all)
    end

    test "adds mobileweb" do
      stats = %Stats{}
      assert 0 == stats |> Stats.attempts(:mobileweb)
      assert 0 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:mobileweb)
      assert 1 == stats |> Stats.attempts(:mobileweb)
      assert 1 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:mobileweb)
      assert 2 == stats |> Stats.attempts(:mobileweb)
      assert 2 == stats |> Stats.attempts(:all)

      assert 0 == stats |> Stats.attempts(:sms)
      assert 0 == stats |> Stats.attempts(:ivr)
      assert 2 == stats |> Stats.attempts(:all)
    end

    test "adds multiple modes" do
      stats = %Stats{}

      assert 0 == stats |> Stats.attempts(:sms)
      assert 0 == stats |> Stats.attempts(:ivr)
      assert 0 == stats |> Stats.attempts(:mobileweb)
      assert 0 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:sms)
      assert 1 == stats |> Stats.attempts(:sms)
      assert 1 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:ivr)
      assert 0 == stats |> Stats.attempts(:ivr)
      assert 1 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:mobileweb)
      assert 1 == stats |> Stats.attempts(:mobileweb)
      assert 2 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:sms)
      assert 2 == stats |> Stats.attempts(:sms)
      assert 3 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.with_last_call_attempted
      assert 1 == stats |> Stats.attempts(:ivr)
      assert 4 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:ivr) |> Stats.with_last_call_attempted
      assert 2 == stats |> Stats.attempts(:ivr)
      assert 5 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:mobileweb)
      assert 2 == stats |> Stats.attempts(:mobileweb)
      assert 6 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:ivr) |> Stats.with_last_call_attempted
      assert 3 == stats |> Stats.attempts(:ivr)
      assert 7 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:mobileweb)
      assert 3 == stats |> Stats.attempts(:mobileweb)
      assert 8 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:mobileweb)
      assert 4 == stats |> Stats.attempts(:mobileweb)
      assert 9 == stats |> Stats.attempts(:all)

      stats = %Stats{}
      assert 0 == stats |> Stats.attempts(:mobileweb)
      assert 0 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:mobileweb)
      assert 1 == stats |> Stats.attempts(:mobileweb)
      assert 1 == stats |> Stats.attempts(:all)

      stats = stats |> Stats.add_attempt(:sms)
      assert 1 == stats |> Stats.attempts(:sms)
      assert 2 == stats |> Stats.attempts(:all)
    end

    test "full counts non-started ivr calls" do
      stats = %Stats{}

      assert 0 == stats |> Stats.attempts(:ivr)
      assert 0 == stats |> Stats.attempts(:all)
      assert 0 == stats |> Stats.attempts(:full)

      stats = stats |> Stats.add_attempt(:sms)
      assert 1 == stats |> Stats.attempts(:sms)
      assert 0 == stats |> Stats.attempts(:ivr)
      assert 1 == stats |> Stats.attempts(:all)
      assert 1 == stats |> Stats.attempts(:full)
      
      stats = stats |> Stats.add_attempt(:mobileweb)
      assert 1 == stats |> Stats.attempts(:mobileweb)
      assert 0 == stats |> Stats.attempts(:ivr)
      assert 2 == stats |> Stats.attempts(:all)
      assert 2 == stats |> Stats.attempts(:full)

      stats = stats |> Stats.add_attempt(:ivr)
      assert 0 == stats |> Stats.attempts(:ivr)
      assert 2 == stats |> Stats.attempts(:all)
      assert 3 == stats |> Stats.attempts(:full)
      
      stats = stats |> Stats.with_last_call_attempted
      assert 1 == stats |> Stats.attempts(:ivr)
      assert 3 == stats |> Stats.attempts(:all)
      assert 3 == stats |> Stats.attempts(:full)
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
    test "total_call_time_seconds calculated from no registered calls" do
      stats = %Stats{}

      assert Stats.total_call_time_seconds(stats) == 0
    end

    test "total_call_time_seconds calculated from a single registered call" do
      stats = %Stats{call_durations: %{"1" => 25}}

      assert Stats.total_call_time_seconds(stats) == 25
    end

    test "total_call_time_seconds calculated from multiple registered calls" do
      stats = %Stats{call_durations: %{"1" => 25, "40" => 40, "any-kind-of-id" => 2, "zero-lenght" => 0}}

      assert Stats.total_call_time_seconds(stats) == 67
    end

    test "total_call_time_seconds backward compatibility" do
      stats = %Stats{total_call_time_seconds: 12}

      assert Stats.total_call_time_seconds(stats) == 12
    end

    test "total_call_time_seconds backward compatibility with registered calls" do
      stats = %Stats{total_call_time_seconds: 12, call_durations: %{"1" => 25, "40" => 40, "any-kind-of-id" => 2, "zero-lenght" => 0}}

      assert Stats.total_call_time_seconds(stats) == 79
    end

    test "total_call_time backward compatibility" do
      stats = %Stats{total_call_time: 1.5}

      assert Stats.total_call_time_seconds(stats) == 90
    end

    test "total_call_time backward compatibility with registered calls" do
      stats = %Stats{total_call_time: 1.5, call_durations: %{"1" => 25, "40" => 40, "any-kind-of-id" => 2, "zero-lenght" => 0}}

      assert Stats.total_call_time_seconds(stats) == 157
    end

    test "resolves to new field in discrepancy" do
      stats = %Stats{total_call_time: 1.5, total_call_time_seconds: 30}

      assert Stats.total_call_time_seconds(stats) == 30
    end

    test "resolves to new field in discrepancy with registered calls" do
      stats = %Stats{total_call_time: 1.5, total_call_time_seconds: 30, call_durations: %{"1" => 25, "40" => 40, "any-kind-of-id" => 2, "zero-lenght" => 0}}

      assert Stats.total_call_time_seconds(stats) == 97
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
