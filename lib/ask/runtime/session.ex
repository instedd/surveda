defmodule Ask.Runtime.Session do
  alias Ask.Runtime.{Flow, Channel}
  defstruct [:phone_number, :channel, :flow]

  def start(questionnaire, phone_number, channel) do
    flow = Flow.start(questionnaire)
    case flow |> Flow.step do
      :end -> :end
      {:ok, flow, {:prompt, prompt}} ->
        channel |> Channel.ask(phone_number, [prompt])
        %Ask.Runtime.Session{
          phone_number: phone_number,
          channel: channel,
          flow: flow
        }
    end
  end

  def sync_step(session) do
    case Flow.step(session.flow) do
      :end -> :end
      {:ok, flow, step} ->
        {:ok, %{session | flow: flow}, step}
    end
  end
end
