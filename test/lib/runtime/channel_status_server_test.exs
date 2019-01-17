defmodule ChannelStatusServerTest do
  use Ask.ModelCase
  use Ask.LogHelper
  use Ask.TestHelpers
  alias Ask.TestChannel
  alias Ask.Runtime.ChannelStatusServer

  test "get_channel_status initially returns :unknown" do
    {:ok, _} = ChannelStatusServer.start_link
    assert ChannelStatusServer.get_channel_status("some_id") == :unknown
  end

  test "poll" do
    {:ok, pid} = ChannelStatusServer.start_link
    Process.register self(), :mail_target

    user = insert(:user)

    surveys = [
      insert(:survey, state: "pending"),
      insert(:survey, state: "running"),
      insert(:survey, state: "running")
    ]

    channels = [
      TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new, 1)),
      TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new, 2)),
      TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new, 3, :down))
    ]

    setup_surveys_with_channels(surveys, channels)

    ChannelStatusServer.poll(pid)

    runtime_channel_1 = TestChannel.new(channels |> Enum.at(0))
    runtime_channel_2 = TestChannel.new(channels |> Enum.at(1))
    runtime_channel_3 = TestChannel.new(channels |> Enum.at(2))

    refute_receive [:check_status, ^runtime_channel_1], 1000
    assert_receive [:check_status, ^runtime_channel_2], 1000
    assert_receive [:check_status, ^runtime_channel_3], 1000
    assert ChannelStatusServer.get_channel_status((channels |> Enum.at(0)).id) == :unknown
    assert ChannelStatusServer.get_channel_status((channels |> Enum.at(1)).id) == :up
    assert ChannelStatusServer.get_channel_status((channels |> Enum.at(2)).id) == {:down, []}
  end

  test "sends email when a channel is down and its status was previously :unknown" do
    {:ok, pid} = ChannelStatusServer.start_link
    Process.register self(), :mail_target
    user = insert(:user)
    survey = insert(:survey, state: "running")
    channel = TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new, 1, :down))
    email = Ask.Email.channel_down(user.email, channel, [])

    setup_surveys_with_channels([survey], [channel])
    ChannelStatusServer.poll(pid)

    assert_receive [:email, ^email]
  end

  test "doesn't send email when a channel is down but was already down" do
    {:ok, pid} = ChannelStatusServer.start_link
    Process.register self(), :mail_target
    user = insert(:user)
    survey = insert(:survey, state: "running")
    channel = TestChannel.create_channel(user, "test", TestChannel.settings(TestChannel.new, 1, :down))
    email = Ask.Email.channel_down(user.email, channel, [])

    setup_surveys_with_channels([survey], [channel])
    ChannelStatusServer.poll(pid)
    assert_receive [:email, ^email]
    ChannelStatusServer.poll(pid)
    refute_receive [:email, ^email]
  end
end
