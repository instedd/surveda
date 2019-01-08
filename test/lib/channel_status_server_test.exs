defmodule ChannelStatusServerTest do
  use Ask.ModelCase
  use Ask.LogHelper
  use Ask.TestHelpers
  alias Ask.{ChannelStatusServer, TestChannel}

  test "get_channel_status initially returns :unknown" do
    {:ok, _} = ChannelStatusServer.start_link
    assert ChannelStatusServer.get_channel_status("some_id") == :unknown
  end

  test "poll" do
    {:ok, pid} = ChannelStatusServer.start_link

    user = insert(:user)

    surveys = [
      insert(:survey, state: "pending"),
      insert(:survey, state: "running")
    ]

    channels = [
      TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new, 1)),
      TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new, 2))
    ]

    setup_surveys_with_channels(surveys, channels)

    ChannelStatusServer.poll(pid)

    runtime_channel_1 = TestChannel.new(channels |> Enum.at(0))
    runtime_channel_2 = TestChannel.new(channels |> Enum.at(1))

    refute_receive [:check_status, ^runtime_channel_1], 1000
    assert_receive [:check_status, ^runtime_channel_2], 1000
    assert ChannelStatusServer.get_channel_status((channels |> Enum.at(0)).id) == :unknown
    assert ChannelStatusServer.get_channel_status((channels |> Enum.at(1)).id) == :up
  end
end
