defmodule Ask.ChannelView do
  use Ask.Web, :view

  def render("index.json", %{channels: channels}) do
    %{data: render_many(channels, Ask.ChannelView, "channel.json")}
  end

  def render("show.json", %{channel: channel}) do
    %{data: render_one(channel, Ask.ChannelView, "channel.json")}
  end

  def render("channel.json", %{channel: channel}) do
    %{
      id: channel.id,
      user_id: channel.user_id,
      name: channel.name,
      type: channel.type,
      provider: channel.provider,
      projects: channel.projects |> Enum.map(& &1.id),
      channelBaseUrl: channel.base_url,
      settings: channel.settings,
      patterns: channel.patterns,
      status_info: channel.status
    }
  end
end
