defmodule Ask.Runtime.Session do
  alias Ask.Runtime.{Flow, Channel}
  alias Ask.Repo
  defstruct [:channel, :flow, :respondent]

  def start(questionnaire, respondent, channel) do
    flow = Flow.start(questionnaire)
    case flow |> Flow.step do
      {:end, _} -> :end
      {:ok, flow, %{prompts: [prompt]}} ->
        runtime_channel = Ask.Channel.runtime_channel(channel)
        runtime_channel |> Channel.ask(respondent.phone_number, [prompt])
        %Ask.Runtime.Session{
          channel: channel,
          flow: flow,
          respondent: respondent
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
    %{
      channel_id: session.channel.id,
      flow: session.flow |> Flow.dump,
      respondent_id: session.respondent.id
    }
  end

  def load(state) do
    %Ask.Runtime.Session{
      channel: Repo.get(Ask.Channel, state["channel_id"]),
      flow: Flow.load(state["flow"]),
      respondent: Repo.get(Ask.Respondent, state["respondent_id"])
    }
  end
end
