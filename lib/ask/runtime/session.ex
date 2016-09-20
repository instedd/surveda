defmodule Ask.Runtime.Session do
  alias Ask.Runtime.{Flow, Channel}
  alias Ask.Repo
  defstruct [:channel, :flow]

  def start(questionnaire, phone_number, channel) do
    flow = Flow.start(questionnaire)
    case flow |> Flow.step do
      {:end, _} -> :end
      {:ok, flow, %{prompts: [prompt]}} ->
        runtime_channel = Ask.Channel.runtime_channel(channel)
        runtime_channel |> Channel.ask(phone_number, [prompt])
        %Ask.Runtime.Session{
          channel: channel,
          flow: flow
        }
    end
  end

  def sync_step(session, _reply) do
    case Flow.step(session.flow) do
      {:end, _} -> :end
      {:ok, flow, %{prompts: [prompt]}} ->
        {:ok, %{session | flow: flow}, {:prompt, prompt}}
    end
  end

  def dump(session) do
    %{channel_id: session.channel.id, flow: session.flow |> Flow.dump}
  end

  def load(state) do
    %Ask.Runtime.Session{
      channel: Repo.get(Ask.Channel, state["channel_id"]),
      flow: Flow.load(state["flow"])
    }
  end
end
