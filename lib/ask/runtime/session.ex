defmodule Ask.Runtime.Session do
  alias Ask.Runtime.{Flow, Channel}
  alias Ask.Repo
  defstruct [:channel, :flow, :respondent]

  def start(questionnaire, respondent, channel) do
    runtime_channel = Ask.Channel.runtime_channel(channel)
    flow = Flow.start(questionnaire, channel.type)
    runtime_channel |> Channel.setup(respondent)

    case runtime_channel |> Channel.can_push_question? do
      true ->
        case flow |> Flow.step do
          {:end, _} -> :end
          {:ok, flow, %{prompts: [prompt]}} ->
            runtime_channel |> Channel.ask(respondent.phone_number, [prompt])
            %Ask.Runtime.Session{
              channel: channel,
              flow: flow,
              respondent: respondent
            }
        end

      false ->
        %Ask.Runtime.Session{
          channel: channel,
          flow: flow,
          respondent: respondent
        }
    end
  end

  def sync_step(session, reply) do
    case Flow.step(session.flow, reply) do
      {:end, %{stores: stores}} ->
        store_responses(session.respondent, stores)
        :end

      {:ok, flow, %{prompts: [prompt], stores: stores}} ->
        store_responses(session.respondent, stores)
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

  defp store_responses(respondent, stores) do
    stores |> Enum.each(fn {field_name, value} ->
      respondent
      |> Ecto.build_assoc(:responses, field_name: field_name, value: value)
      |> Ask.Repo.insert
    end)
  end
end
