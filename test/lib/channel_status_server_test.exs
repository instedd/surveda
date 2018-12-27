defmodule ChannelStatusServerTest do
  use Ask.ModelCase
  use Ask.LogHelper
  alias Ask.ChannelStatusServer


  @channel_id 10

  test "it runs 'timer' every 10 minutes" do
    {:ok, _} = ChannelStatusServer.start_link
    #wait 10 minutes
    #check :timer received
    #wait another 10 minutes
    #check :timer received
    #end
  end

  test "getChannelStatus initially returns :unknown" do
    {:ok, pid} = ChannelStatusServer.start_link
    assert ChannelStatusServer.getChannelStatus(pid, @channel_id) == :unknown
  end

  test "update" do
    {:ok, pid} = ChannelStatusServer.start_link
    ChannelStatusServer.update(pid, @channel_id, :my_status)
    assert ChannelStatusServer.getChannelStatus(pid, @channel_id) == :my_status
  end
end
