defmodule Ask.Runtime.ChannelBrokerStateTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers
  alias Ask.Runtime.ChannelBrokerState, as: State

  setup do
    mock_queued_contact = fn respondent_id, params, disposition ->
      {%{id: respondent_id, disposition: disposition}, params}
    end

    {:ok, state: State.new(0, %{}), mock_queued_contact: mock_queued_contact}
  end

  test "queues contact", %{state: state, mock_queued_contact: mqc} do
    respondent_id = 2
    params = 3
    disposition = 4
    contact = mqc.(respondent_id, params, disposition)
    size = 5

    %{contacts_queue: q} = State.queue_contact(state, contact, size)

    {{:value, [queud_size, queued_contact]}, _} = :pqueue.out(q)
    assert queued_contact == {%{id: respondent_id, disposition: disposition}, params}
    assert queud_size == size
  end

  test "removes the respondent", %{state: state, mock_queued_contact: mqc} do
    respondent_id = 2
    contact = mqc.(respondent_id, 3, 4)
    size = 5
    state = State.queue_contact(state, contact, size)

    %{contacts_queue: q} = State.remove_from_queue(state, respondent_id)

    assert :pqueue.is_empty(q)
  end

  test "doesn't removes other respondent", %{state: state, mock_queued_contact: mqc} do
    respondent_id = 2
    contact = mqc.(respondent_id, 3, 4)
    size = 5
    state = State.queue_contact(state, contact, size)

    new_state = State.remove_from_queue(state, 6)

    assert new_state == state
  end
end
