defmodule Ask.Runtime.ChannelBrokerTest do
  use Ask.DataCase
  use Ask.TestHelpers
  alias Ask.Runtime.ChannelStatusServer

  setup do
    {:ok, _} = ChannelStatusServer.start_link()
    :ok
  end

  @respondents_quantity 10

  describe "Verboice" do
    test "Every Call is made when capacity isn't set", %{} do
      channel_capacity = nil
      test_channel = initialize_survey("ivr", channel_capacity)

      broker_poll()

      assert_made_calls(@respondents_quantity, test_channel)
    end

    @tag :skip
    test "Calls aren't made while the channel capacity is full", %{} do
      channel_capacity = 5
      test_channel = initialize_survey("ivr", channel_capacity)

      broker_poll()

      assert_made_calls(channel_capacity, test_channel)
    end
  end

  describe "Nuntium" do
    test "Every SMS is sent when capacity isn't set", %{} do
      channel_capacity = nil
      test_channel = initialize_survey("sms", channel_capacity)

      broker_poll()

      assert_sent_smss(@respondents_quantity, test_channel)
    end

    @tag :skip
    test "SMS aren't sent while the channel capacity is full", %{} do
      channel_capacity = 5
      test_channel = initialize_survey("sms", channel_capacity)

      broker_poll()

      assert_sent_smss(channel_capacity, test_channel)
    end
  end

  defp assert_made_calls(n, test_channel) do
    for _ <- 1..n do
      assert_received [:setup, ^test_channel, _respondent, _token]
    end
    refute_received [:setup, ^test_channel, _respondent, _token]
  end

  defp assert_sent_smss(n, test_channel) do
    for _ <- 1..n do
      assert_received [:ask, ^test_channel, _respondent, _token, _reply]
    end
    refute_received [:ask, ^test_channel, _respondent, _token, _reply]
  end

  defp initialize_survey(mode, channel_capacity) do
    [_survey, _group, test_channel, _respondents] =
      create_running_survey_with_channel_and_respondents_with_options(
        mode: mode,
        respondents_quantity: @respondents_quantity,
        channel_capacity: channel_capacity
      )
    test_channel
  end
end
