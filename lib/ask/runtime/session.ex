defmodule Ask.Runtime.Session do
  use GenServer
  alias Ask.Runtime.{Flow, Channel}
  defstruct [:questionnaire, :phone_number, :channel, :flow]

  def start(questionnaire, phone_number, channel) do
    GenServer.start_link(__MODULE__, [questionnaire, phone_number, channel])
  end

  def init([questionnaire, phone_number, channel]) do
    GenServer.cast(self(), :setup)
    flow = Flow.start(questionnaire)
    {:ok, %Ask.Runtime.Session{
      questionnaire: questionnaire,
      phone_number: phone_number,
      channel: channel,
      flow: flow
    }}
  end

  def handle_cast(:setup, session) do
    case session.flow |> Flow.step do
      :end ->
        {:stop, :normal, %{session | flow: nil}}

      {:ok, flow, {:prompt, prompt}} ->
        session.channel |> Channel.ask(session.phone_number, [prompt])
        {:noreply, %{session | flow: flow}}
    end
  end
end
