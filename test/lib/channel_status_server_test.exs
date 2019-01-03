defmodule ChannelStatusServerTest do
  use Ask.ModelCase
  use Ask.LogHelper
  use Ask.TestHelpers
  alias Ask.{ChannelStatusServer, TestChannel}


  @channel_id 10

  test "it runs 'timer' every 10 minutes" do
    {:ok, _} = ChannelStatusServer.start_link
    #wait 10 minutes
    #check :timer received
    #wait another 10 minutes
    #check :timer received
    #end
  end

  test "get_channel_status initially returns :unknown" do
    {:ok, _} = ChannelStatusServer.start_link
    assert ChannelStatusServer.get_channel_status(@channel_id) == :unknown
  end

  test "update" do
    {:ok, _} = ChannelStatusServer.start_link
    ChannelStatusServer.update(@channel_id, :my_status)
    assert ChannelStatusServer.get_channel_status(@channel_id) == :my_status
  end

  test "poll" do
    {:ok, _} = ChannelStatusServer.start_link

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

    ChannelStatusServer.poll()

    runtime_channel_1 = TestChannel.new(channels |> Enum.at(0))
    runtime_channel_2 = TestChannel.new(channels |> Enum.at(1))

    refute_receive [:check_status, ^runtime_channel_1], 1000
    assert_receive [:check_status, ^runtime_channel_2], 1000
  end
end
