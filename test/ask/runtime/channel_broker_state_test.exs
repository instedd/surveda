defmodule Ask.Runtime.ChannelBrokerStateTest do
  use AskWeb.ConnCase
  use Ask.TestHelpers
  use Ask.MockTime

  alias Ask.ChannelBrokerQueue, as: Queue
  alias Ask.Runtime.ChannelBrokerState, as: State

  setup do
    {:ok, state: State.new(0, "ivr", %{"capacity" => 4})}
  end

  describe ".inactive?" do
    test "returns true when empty", %{state: state} do
      assert state
      |> State.inactive?()
    end

    test "returns true if any pending contact", %{state: state} do
      refute state
      |> State.queue_contact(new_contact(2), 1)
      |> State.inactive?()
    end

    test "returns true if any active contact", %{state: state} do
      refute state
      |> State.queue_contact(new_contact(2), 1)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.inactive?()
    end
  end

  describe ".queued_or_active?" do
    test "returns true if respondent in queue", %{state: state} do
      assert state
      |> State.queue_contact(new_contact(2), 1)
      |> State.queued_or_active?(2)
    end

    test "returns true if respondent is active", %{state: state} do
      assert state
      |> State.queue_contact(new_contact(2), 1)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.queued_or_active?(2)
    end

    test "returns false otherwise", %{state: state} do
      refute state
      |> State.queued_or_active?(2)
    end
  end

  describe ".queue_contact" do
    @tag :time_mock
    test "queues ivr contact", %{state: state} do
      now = DateTime.utc_now()
      mock_time(now)
      State.queue_contact(state, {%{id: 2, disposition: :queued}, "secret", nil, nil}, 5)

      assert [%{respondent_id: 2, size: 5, queued_at: now}] = Queue.queued_contacts(0)
      assert [] = Queue.active_contacts(0)
    end

    @tag :time_mock
    test "queues sms contact" do
      now = DateTime.utc_now()
      mock_time(now)

      State.new(0, "sms", %{})
      |> State.queue_contact({%{id: 2, disposition: :queued}, "secret", []}, 5)

      assert [%{respondent_id: 2, size: 5, queued_at: now, reply: []}] = Queue.queued_contacts(0)
      assert [] = Queue.active_contacts(0)
    end

    test "sets priority from respondent's disposition", %{state: state} do
      state
      |> State.queue_contact(new_contact(1, :queued), 1)
      |> State.queue_contact(new_contact(2, :started), 1)

      assert [
        %{respondent_id: 1, priority: :normal},
        %{respondent_id: 2, priority: :high},
      ] = Queue.queued_contacts(0)
      assert [] = Queue.active_contacts(0)
    end
  end

  test "channel state", %{state: state} do
    channel_state =
      state
      |> State.queue_contact(new_contact(1), 1)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.put_channel_state(1, %{"verboice_id" => 123})
      |> State.get_channel_state(1)
    assert channel_state == %{"verboice_id" => 123}

    channel_state =
      state
      |> State.queue_contact(new_contact(2), 1)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.get_channel_state(2)
    assert channel_state == %{}
  end

  describe ".touch_last_contact" do
    test "", %{state: state} do
      state
      |> State.queue_contact(new_contact(1), 1)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.touch_last_contact(1)

      assert [%{respondent_id: 1}] = Queue.active_contacts(0)
    end
  end

  describe ".can_unqueue" do
    test "returns false when no pending contacts", %{state: state} do
      refute state
      |> State.can_unqueue()
    end

    test "returns false when non activable contacts", %{state: state} do
      refute state
      |> State.queue_contact(new_contact(1, :queued, DateTime.utc_now() |> DateTime.add(7200, :second)), 1)
      |> State.can_unqueue()
    end

    test "returns true when activable contacts (not_before <= now)", %{state: state} do
      assert state
      |> State.queue_contact(new_contact(1, :queued, DateTime.utc_now() |> DateTime.add(-1, :second)), 1)
      |> State.can_unqueue()
    end

    test "returns true when activable contacts (not_before <= now + leeway)", %{state: state} do
      assert state
      |> State.queue_contact(new_contact(1, :queued, DateTime.utc_now() |> DateTime.add(50, :second)), 1)
      |> State.can_unqueue()
    end

    test "returns true when activable contacts (not_before is null)", %{state: state} do
      assert state
      |> State.queue_contact(new_contact(1, nil), 1)
      |> State.can_unqueue()
    end

    test "returns false when capacity is reached", %{state: state} do
      refute state
      |> State.queue_contact(new_contact(1), 1) |> State.activate_next_in_queue() |> elem(0)
      |> State.queue_contact(new_contact(2), 2) |> State.activate_next_in_queue() |> elem(0)
      |> State.queue_contact(new_contact(3), 3) |> State.activate_next_in_queue() |> elem(0)
      |> State.queue_contact(new_contact(4), 1)
      |> State.can_unqueue()
    end
  end

  describe ".activate_next_in_queue" do
    @tag :time_mock
    test "activates contact", %{state: state} do
      now = DateTime.utc_now()
      mock_time(now)

      state
      |> State.queue_contact(new_contact(1), 2)
      |> State.activate_next_in_queue()

      assert [%{
        respondent_id: 1,
        contacts: 2,
        last_contact: now
      }] = Queue.active_contacts(0)
    end

    test "returns unqueued ivr contact" do
      respondent = insert(:respondent)
      respondent_id = respondent.id

      {_, contact} =
        State.new(0, "ivr", %{})
        |> State.queue_contact({respondent, "secret", nil, nil}, 2)
        |> State.activate_next_in_queue()

      assert {%Ask.Respondent{id: ^respondent_id}, "secret", nil, nil} = contact
    end

    test "returns unqueued sms contact" do
      respondent = insert(:respondent)
      respondent_id = respondent.id

      {_, contact} =
        State.new(0, "sms", %{})
        |> State.queue_contact({respondent, "secret", []}, 2)
        |> State.activate_next_in_queue()

      assert {%Ask.Respondent{id: ^respondent_id}, "secret", []} = contact
    end

    @tag :time_mock
    test "activates contacts by priority then queued time", %{state: state} do
      now = DateTime.utc_now()

      # queue a new contact every second
      mock_time(now)
      state = State.queue_contact(state, new_contact(1), 1, :normal)

      mock_time(DateTime.add(now, 1, :second))
      state = State.queue_contact(state, new_contact(2), 1, :high)

      mock_time(DateTime.add(now, 2, :second))
      state = State.queue_contact(state, new_contact(3), 1, :low)

      mock_time(DateTime.add(now, 3, :second))
      state = State.queue_contact(state, new_contact(4), 1, :normal)

      mock_time(DateTime.add(now, 5, :second))
      state = State.queue_contact(state, new_contact(5), 1, :low)

      # 1. high priority
      {state, _} = State.activate_next_in_queue(state)
      assert [2] = Queue.active_contacts(0) |> Enum.map(fn c -> c.respondent_id end) |> Enum.sort()

      # 2. normal priority queued 1st
      {state, _} = State.activate_next_in_queue(state)
      assert [1, 2] = Queue.active_contacts(0) |> Enum.map(fn c -> c.respondent_id end) |> Enum.sort()

      # 3. normal priority queued 2nd
      {state, _} = State.activate_next_in_queue(state)
      assert [1, 2, 4] = Queue.active_contacts(0) |> Enum.map(fn c -> c.respondent_id end) |> Enum.sort()

      # 4. low priority queued 1st
      {_, _} = State.activate_next_in_queue(state)
      assert [1, 2, 3, 4] = Queue.active_contacts(0) |> Enum.map(fn c -> c.respondent_id end) |> Enum.sort()
      assert [%{respondent_id: 5}] = Queue.queued_contacts(0)
    end

    @tag :time_mock
    test "skips respondent until not_before <= now + leeway", %{state: state} do
      now = DateTime.utc_now()
      mock_time(now)

      state
      |> State.queue_contact(new_contact(1, :queued, DateTime.add(now, 90, :second)), 1)
      |> State.queue_contact(new_contact(2, :queued, DateTime.add(now, 80, :second)), 1)
      |> State.queue_contact(new_contact(3), 1)

      mock_time(DateTime.add(now, 15, :second))
      {state, _} = State.activate_next_in_queue(state)
      assert [3] = Queue.active_contacts(0) |> Enum.map(fn c -> c.respondent_id end) |> Enum.sort()

      mock_time(DateTime.add(now, 25, :second))
      {state, _} = State.activate_next_in_queue(state)
      assert [2, 3] = Queue.active_contacts(0) |> Enum.map(fn c -> c.respondent_id end) |> Enum.sort()

      mock_time(DateTime.add(now, 35, :second))
      {_, _} = State.activate_next_in_queue(state)
      assert [1, 2, 3] = Queue.active_contacts(0) |> Enum.map(fn c -> c.respondent_id end) |> Enum.sort()
    end
  end

  describe ".deactivate_contact" do
    test "removes from the queue", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 5)
      |> State.deactivate_contact(2)

      assert [] = Queue.queued_contacts(0)
      assert [] = Queue.active_contacts(0)
    end

    test "removes from the active queue", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 5)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.deactivate_contact(2)

      assert [] = Queue.queued_contacts(0)
      assert [] = Queue.active_contacts(0)
    end

    test "silently fails for unknown respondent", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 5)
      |> State.deactivate_contact(6)

      assert [%{respondent_id: 2}] = Queue.queued_contacts(0)
      assert [] = Queue.active_contacts(0)
    end
  end

  describe ".increment_respondents_contacts" do
    test "increments the number of contacts for a respondent", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 5)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.increment_respondents_contacts(2, 3)

      assert [] = Queue.queued_contacts(0)
      assert [%{respondent_id: 2, contacts: 8}] = Queue.active_contacts(0)
    end

    test "activates the contact", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 3)
      |> State.increment_respondents_contacts(2, 1)

      assert [] = Queue.queued_contacts(0)
      assert [%{respondent_id: 2, contacts: 1}] = Queue.active_contacts(0)
    end

    test "silently fails for unknown respondent", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 5)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.increment_respondents_contacts(6, 1)

      assert [] = Queue.queued_contacts(0)
      assert [%{respondent_id: 2, contacts: 5}] = Queue.active_contacts(0)
    end
  end

  describe ".decrement_respondents_contacts" do
    test "decrements the number of contacts for a respondent", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 5)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.decrement_respondents_contacts(2, 3)

      assert [] = Queue.queued_contacts(0)
      assert [%{respondent_id: 2, contacts: 2}] = Queue.active_contacts(0)
    end

    test "deletes the contact when number of contacts reaches zero (or less)", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 5)
      |> State.queue_contact(new_contact(4), 3)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.decrement_respondents_contacts(2, 5)
      |> State.decrement_respondents_contacts(4, 7)

      assert [] = Queue.queued_contacts(0)
      assert [] = Queue.active_contacts(0)
    end

    test "silently fails for unknown respondent", %{state: state} do
      state
      |> State.queue_contact(new_contact(2), 5)
      |> State.activate_next_in_queue() |> elem(0)
      |> State.decrement_respondents_contacts(6, 1)

      assert [] = Queue.queued_contacts(0)
      assert [%{respondent_id: 2, contacts: 5}] = Queue.active_contacts(0)
    end
  end

  describe ".reenqueue_contact" do
    @tag :time_mock
    test "deactivates the contact and puts it back into queue", %{state: state} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      mock_time(now)

      {new_state, _} =
        state
        |> State.queue_contact(new_contact(2), 1)
        |> State.activate_next_in_queue()

      later = DateTime.add(now, 600, :second)
      mock_time(later)

      State.reenqueue_contact(new_state, 2)

      assert [%{
        respondent_id: 2,
        contacts: nil,
        last_contact: nil,
        channel_state: nil,
        queued_at: later
      }] = Queue.queued_contacts(0)
      assert [] = Queue.active_contacts(0)
    end
  end

  defp new_contact(respondent_id, disposition \\ :queued, not_before \\ nil) do
    {%{id: respondent_id, disposition: disposition}, "secret", not_before, nil}
  end
end
