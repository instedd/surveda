defmodule Ask.Runtime.ChannelBrokerTest do
  use AskWeb.ConnCase
  use Ask.MockTime
  use Ask.TestHelpers

  alias Ask.Runtime.{
    ChannelStatusServer,
    ChannelBroker,
    VerboiceChannel,
    NuntiumChannel
  }

  alias Ask.{Config, Channel}
  import Mock

  setup %{conn: conn} do
    on_exit(fn ->
      ChannelBrokerSupervisor.terminate_children()
      ChannelBrokerAgent.clear()
    end)

    {:ok, _} = ChannelStatusServer.start_link()
    {:ok, conn: conn}
  end

  @channel_capacity 5
  @respondents_quantity 10

  describe "Verboice" do
    test "Every Call is made when capacity isn't set", %{} do
      channel_capacity = nil
      [test_channel, respondents, _channel] = initialize_survey("ivr", channel_capacity)

      broker_poll()

      assert_made_calls(respondents, test_channel)
    end

    test "Calls aren't made while the channel capacity is full", %{conn: conn} do
      # Arrange
      channel_capacity = 5
      [test_channel, respondents, _channel] = initialize_survey("ivr", channel_capacity)

      # Act
      broker_poll()

      # Assert
      verify_state(respondents, :active)
      assert_made_calls(Enum.take(respondents, channel_capacity), test_channel)
      pending_respondents = Enum.drop(respondents, channel_capacity)

      # Arrange
      callbacks = 2
      release_respondents = Enum.take(respondents, callbacks)

      # Act
      callback_respondents(conn, release_respondents, "verboice")

      # Assert
      assert_some_made_calls(callbacks, pending_respondents, test_channel)
    end

    test "Skips expired calls" do
      %{state: state, respondents: respondents} = build_survey("ivr")

      now = SystemTime.time().now
      not_before = DateTime.add(now, 5, :second)
      not_after = DateTime.add(now, 60, :second)
      expired = DateTime.add(now, -5, :second)

      with_mock Ask.Runtime.Survey, [contact_attempt_expired: fn _ -> :ok end] do
        state =
          state
          |> activate_respondent("ivr", Enum.at(respondents, 0), not_before, not_after)
          |> activate_respondent("ivr", Enum.at(respondents, 1), not_before, expired)
          |> activate_respondent("ivr", Enum.at(respondents, 2), not_before, expired)
          |> activate_respondent("ivr", Enum.at(respondents, 3), not_before, not_after)
          |> activate_respondent("ivr", Enum.at(respondents, 4), not_before, not_after)

        assert [
               Enum.at(respondents, 0).id,
               Enum.at(respondents, 3).id,
               Enum.at(respondents, 4).id
             ] == active_respondent_ids(state)

        assert_not_called(Ask.Runtime.Survey.contact_attempt_expired(%{id: Enum.at(respondents, 0).id}))
        assert_called_exactly(Ask.Runtime.Survey.contact_attempt_expired(%{id: Enum.at(respondents, 1).id}), 1)
        assert_called_exactly(Ask.Runtime.Survey.contact_attempt_expired(%{id: Enum.at(respondents, 2).id}), 1)
        assert_not_called(Ask.Runtime.Survey.contact_attempt_expired(%{id: Enum.at(respondents, 3).id}))
        assert_not_called(Ask.Runtime.Survey.contact_attempt_expired(%{id: Enum.at(respondents, 4).id}))
      end
    end

    @tag :time_mock
    test "Reschedules calls scheduled for the future" do
      set_actual_time()

      %{state: state, respondents: respondents} = build_survey("ivr")

      now = SystemTime.time().now
      not_before = DateTime.add(now, 5, :second)
      not_after = DateTime.add(now, 3600, :second)
      the_future = DateTime.add(now, 180, :second)

      state =
        state
        |> activate_respondent("ivr", Enum.at(respondents, 0), not_before, not_after)
        |> activate_respondent("ivr", Enum.at(respondents, 1), the_future, not_after)
        |> activate_respondent("ivr", Enum.at(respondents, 2), not_before, not_after)
        |> activate_respondent("ivr", Enum.at(respondents, 3), the_future, not_after)
        |> activate_respondent("ivr", Enum.at(respondents, 4), not_before, not_after)

      # activated soon to be contacted respondents:
      assert [
               Enum.at(respondents, 0).id,
               Enum.at(respondents, 2).id,
               Enum.at(respondents, 4).id
             ] == active_respondent_ids(state)

      # skip to the future
      time_passes(minutes: 5)

      # trigger more enqueues (by pushing more contacts):
      state =
        state
        |> activate_respondent("ivr", Enum.at(respondents, 5), not_after, not_after)
        |> activate_respondent("ivr", Enum.at(respondents, 7), not_after, not_after)

      assert [
               Enum.at(respondents, 0).id,
               Enum.at(respondents, 1).id,
               Enum.at(respondents, 2).id,
               Enum.at(respondents, 3).id,
               Enum.at(respondents, 4).id
             ] == active_respondent_ids(state)
    end

    defp activate_respondent(state, "ivr", respondent, not_before, not_after) do
      {_, state, _} =
        ChannelBroker.handle_cast(
          {:setup, "ivr", respondent, "token", not_before, not_after},
          state
        )

      state
    end
  end

  describe "Nuntium" do
    test "Every SMS is sent when capacity isn't set", %{} do
      channel_capacity = nil
      [test_channel, respondents, _channel] = initialize_survey("sms", channel_capacity)

      broker_poll()

      assert_sent_smss(respondents, test_channel)
    end

    test "SMS aren't sent while the channel capacity is full", %{conn: conn} do
      # Arrange
      channel_capacity = 4
      [test_channel, respondents, channel] = initialize_survey("sms", channel_capacity)

      # Act
      broker_poll()

      # Assert
      verify_state(respondents, :active)
      assert_sent_smss(Enum.take(respondents, channel_capacity), test_channel)
      pending_respondents = Enum.drop(respondents, channel_capacity)

      # Arrange
      callbacks = 4
      release_respondents = Enum.take(respondents, callbacks)

      # Act
      callback_respondents(conn, release_respondents, "nuntium", channel.id)

      # Assert
      assert_some_sent_smss(callbacks, pending_respondents, test_channel)
    end
  end

  describe ":collect_garbage" do
    @describetag :time_mock

    setup do
      set_actual_time()
      :ok
    end

    test "deactivates failed respondents" do
      %{state: state, respondents: respondents} = start_survey("ivr")

      # fail some respondents:
      Enum.at(respondents, 1) |> Respondent.changeset(%{state: :failed}) |> Repo.update!()
      Enum.at(respondents, 3) |> Respondent.changeset(%{state: :failed}) |> Repo.update!()
      Enum.at(respondents, 4) |> Respondent.changeset(%{state: :failed}) |> Repo.update!()

      # run:
      {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage}, state)

      # it removed failed respondents (1, 3, 4):
      active_respondent_ids = active_respondent_ids(new_state)
      assert Enum.at(respondents, 0).id in active_respondent_ids
      assert Enum.at(respondents, 1).id not in active_respondent_ids
      assert Enum.at(respondents, 2).id in active_respondent_ids
      assert Enum.at(respondents, 3).id not in active_respondent_ids
      assert Enum.at(respondents, 4).id not in active_respondent_ids

      # and activated three of the pending ones (order depends on MySQL version):
      assert_some_in_both(
        3,
        respondents |> Enum.drop(5) |> Enum.map(& &1id),
        active_respondent_ids
      )
    end

    test "asks verboice for actual state of long idle contacts" do
      %{state: state, respondents: respondents} = start_survey("ivr")
      initial_active = active_respondent_ids(state)

      # travel to the future (within allowed contact idle time):
      time_passes(minutes: trunc(state.config.gc_active_idle_minutes / 2))
      {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage}, state)
      assert active_respondent_ids(new_state) == initial_active

      # travel to the future again (after allowed contact idle time):
      time_passes(minutes: state.config.gc_active_idle_minutes * 2)

      # mock calls to channel:
      verboice_message_inactive_fn = fn _, %{"verboice_call_id" => call_id} ->
        call_id in [
          Enum.at(respondents, 0).id,
          Enum.at(respondents, 1).id,
          Enum.at(respondents, 3).id
        ]
      end

      # FIXME: mocks aren't needed, TestChannel forwards calls to the spec process (use `assert_received`)
      mocks = [
        about_to_expire?: fn _ -> false end,
        message_inactive?: verboice_message_inactive_fn,
        setup: fn _, r, _, _, _ -> {:ok, %{verboice_call_id: r.id}} end
      ]

      with_mock Ask.Runtime.Channel, mocks do
        {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage}, state)

        # it asked verboice for call state (all calls are long idle in this test case):
        assert_called_exactly(Ask.Runtime.Channel.message_inactive?(:_, :_), @channel_capacity)

        # it removed inactive respondents (0, 1, 3):
        active_respondent_ids = active_respondent_ids(new_state)
        assert Enum.at(respondents, 0).id not in active_respondent_ids
        assert Enum.at(respondents, 1).id not in active_respondent_ids
        assert Enum.at(respondents, 2).id in active_respondent_ids
        assert Enum.at(respondents, 3).id not in active_respondent_ids
        assert Enum.at(respondents, 4).id in active_respondent_ids

        # and activated three of the pending ones (order depends on MySQL version):
        assert_some_in_both(
          3,
          respondents |> Enum.drop(5) |> Enum.map(& &1id),
          active_respondent_ids
        )
      end
    end

    test "asks nuntium for actual state of long idle contacts" do
      %{state: state, respondents: respondents} = start_survey("sms")
      initial_active = active_respondent_ids(state)

      # travel to the future (within allowed contact idle time):
      time_passes(minutes: trunc(state.config.gc_active_idle_minutes / 2))
      {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage}, state)
      assert active_respondent_ids(new_state) == initial_active

      # travel to the future again (after allowed contact idle time):
      time_passes(minutes: state.config.gc_active_idle_minutes * 2)

      # mock calls to channel:
      nuntium_message_inactive_fn = fn _, %{"nuntium_token" => nuntium_token} ->
        nuntium_token in [
          Enum.at(respondents, 0).id,
          Enum.at(respondents, 1).id,
          Enum.at(respondents, 4).id
        ]
      end

      # FIXME: mocks aren't needed, TestChannel forwards calls to the spec process (use `assert_received`)
      mocks = [
        about_to_expire?: fn _ -> false end,
        message_inactive?: nuntium_message_inactive_fn,
        setup: fn _, _, _, _, _ -> {:ok, %{}} end,
        ask: fn _, r, _, _, _ -> {:ok, %{nuntium_token: r.id}} end
      ]

      with_mock Ask.Runtime.Channel, mocks do
        {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage}, state)

        # it asked nuntium for call state (all messages are long idle in this test case):
        assert_called_exactly(Ask.Runtime.Channel.message_inactive?(:_, :_), @channel_capacity)

        # it removed inactive respondents (0, 1, 4):
        active_respondent_ids = active_respondent_ids(new_state)
        assert Enum.at(respondents, 0).id not in active_respondent_ids
        assert Enum.at(respondents, 1).id not in active_respondent_ids
        assert Enum.at(respondents, 2).id in active_respondent_ids
        assert Enum.at(respondents, 3).id in active_respondent_ids
        assert Enum.at(respondents, 4).id not in active_respondent_ids

        # and activated three of the pending ones (order depends on MySQL version):
        assert_some_in_both(
          3,
          respondents |> Enum.drop(5) |> Enum.map(& &1id),
          active_respondent_ids
        )
      end
    end
  end

  describe "on_channel_settings_change" do
    test "capacity is updated" do
      # Arrange
      first_capacity = 4
      [test_channel, respondents, _channel] = initialize_survey("sms", first_capacity)
      channel = Repo.one(Channel)
      updated_capacity = 6
      new_settings = Map.put(channel.settings, "capacity", updated_capacity)

      # Act
      ChannelBroker.on_channel_settings_change(channel.id, new_settings)
      broker_poll()

      # Assert
      assert_sent_smss(Enum.take(respondents, updated_capacity), test_channel)
    end
  end

  defp assert_made_calls(respondents, test_channel) do
    Enum.each(respondents, fn %{id: id} ->
      assert_received [:setup, ^test_channel, %{id: ^id}, _token]
    end)

    refute_received [:setup, ^test_channel, _respondent, _token]
  end

  defp assert_some_made_calls(amount, respondents, test_channel) do
    respondent_ids = Enum.map(respondents, & &1.id)

    Stream.repeatedly(fn ->
      assert_received [:setup, ^test_channel, %{id: id}, _token]
      assert Enum.member?(respondent_ids, id)
    end) |> Enum.take(amount)

    refute_received [:setup, ^test_channel, _respondent, _token]
  end

  defp assert_sent_smss(respondents, test_channel) do
    Enum.each(respondents, fn %{id: id} ->
      assert_received [:ask, ^test_channel, %{id: ^id}, _token, _reply, _channel_id]
    end)

    refute_received [:ask, ^test_channel, _respondent, _token, _reply, _channel_id]
  end

  defp assert_some_sent_smss(amount, respondents, test_channel) do
    respondent_ids = Enum.map(respondents, & &1.id)

    Stream.repeatedly(fn ->
      assert_received [:ask, ^test_channel, %{id: id}, _token, _reply, _channel_id]
      assert Enum.member?(respondent_ids, id)
    end) |> Enum.take(amount)

    refute_received [:ask, ^test_channel, _respondent, _token, _reply, _channel_id]
  end

  defp assert_some_in_both(amount, an_enum, other_enum) do
    assert MapSet.new(an_enum)
      |> MapSet.intersection(MapSet.new(other_enum))
      |> Enum.count == amount
  end

  defp initialize_survey(mode, channel_capacity) do
    [_survey, _group, test_channel, respondents, channel] =
      create_running_survey_with_channel_and_respondents_with_options(
        mode: mode,
        respondents_quantity: @respondents_quantity,
        channel_capacity: channel_capacity
      )

    [test_channel, respondents, channel]
  end

  defp build_survey(channel_type) do
    # create survey:
    [test_channel, respondents, channel] = initialize_survey(channel_type, @channel_capacity)

    # pre-activate respondents:
    from(r in Respondent, where: r.id in ^Enum.map(respondents, fn r -> r.id end))
    |> Repo.update_all(set: [state: "active"])

    # build state
    state = %Ask.Runtime.ChannelBrokerState{
      channel_id: channel.id,
      channel_type: channel.type,
      runtime_channel: test_channel,
      capacity: @channel_capacity,
      config: Config.channel_broker_config()
    }

    %{state: state, respondents: respondents, channel: channel}
  end

  defp start_survey(channel_type) do
    %{state: state, respondents: respondents, channel: channel} = build_survey(channel_type)

    # queue respondents:
    state =
      Enum.reduce(respondents, state, fn respondent, state ->
        contact = respondent_to_contact(channel_type, respondent)
        state |> Ask.Runtime.ChannelBrokerState.queue_contact(contact, 1, :normal)
      end)

    # force activate respondents (up to capacity):
    state =
      respondents
      |> Enum.slice(0..4)
      |> Enum.reduce(state, fn respondent, state ->
        state
        |> Ask.Runtime.ChannelBrokerState.increment_respondents_contacts(respondent.id, 1)
        |> Ask.Runtime.ChannelBrokerState.put_channel_state(
          respondent.id,
          channel_state(channel.type, respondent)
        )
      end)

    %{state: state, respondents: respondents, channel: channel}
  end

  defp respondent_to_contact("ivr", respondent) do
    not_before = SystemTime.time().now |> DateTime.add(-3600, :second)
    not_after = SystemTime.time().now |> DateTime.add(3600, :second)
    {respondent, "secret", not_before, not_after}
  end

  defp respondent_to_contact("sms", respondent) do
    {respondent, "secret", []}
  end

  defp channel_state("ivr", respondent) do
    %{"verboice_call_id" => respondent.id}
  end

  defp channel_state("sms", respondent) do
    %{"nuntium_token" => respondent.id}
  end

  defp callback_respondents(conn, respondents, "nuntium" = _provider, channel_id) do
    Enum.each(respondents, fn %{id: id} ->
      NuntiumChannel.callback(conn, %{
        "path" => ["status"],
        "respondent_id" => "#{id}",
        "state" => "delivered",
        "channel_id" => "#{channel_id}"
      })
    end)
  end

  defp callback_respondents(conn, respondents, "verboice" = _provider) do
    Enum.each(respondents, fn %{id: id} ->
      VerboiceChannel.callback(conn, %{
        "path" => ["status", id, "token"],
        "CallStatus" => "completed",
        "CallDuration" => "15",
        "CallSid" => "1"
      })
    end)
  end

  defp verify_state(respondents, state) do
    Enum.each(respondents, fn %{id: id} ->
      assert Repo.get(Respondent, id).state == state
    end)
  end

  defp active_respondent_ids(state) do
    Ask.ChannelBrokerQueue.active_contacts(state.channel_id)
    |> Enum.map(fn c -> c.respondent_id end)
  end
end
