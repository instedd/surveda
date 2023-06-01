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

      # Arrange
      callbacks = 2
      release_respondents = Enum.take(respondents, callbacks)

      # Act
      callback_respondents(conn, release_respondents, "verboice")

      # Assert
      released_respondents =
        Enum.take(respondents, channel_capacity + callbacks) |> Enum.take(-callbacks)

      assert_made_calls(released_respondents, test_channel)
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

      # Arrange
      callbacks = 4
      release_respondents = Enum.take(respondents, callbacks)

      # Act
      callback_respondents(conn, release_respondents, "nuntium", channel.id)

      # Assert
      released_respondents =
        Enum.take(respondents, channel_capacity + callbacks) |> Enum.take(-callbacks)

      assert_sent_smss(released_respondents, test_channel)
    end
  end

  describe ":collect_garbage" do
    @describetag :time_mock
    @channel_capacity 5

    setup do
      set_actual_time()
      :ok
    end

    defp channel_state("ivr", respondent) do
      %{"verboice_call_id" => respondent.id}
    end

    defp channel_state("sms", respondent) do
      %{"nuntium_token" => respondent.id}
    end

    defp start_survey(channel_type) do
      # create survey:
      [test_channel, respondents, channel] = initialize_survey(channel_type, @channel_capacity)

      # activate respondents:
      from(r in Respondent, where: r.id in ^Enum.map(respondents, fn r -> r.id end))
      |> Repo.update_all(set: [state: "active"])

      active_contacts =
        respondents
        |> Enum.slice(0..4)
        |> Enum.reduce(%{}, fn e, a ->
          Map.put(a, e.id, %{
            contacts: 1,
            last_contact: Ask.SystemTime.time().now,
            channel_state: channel_state(channel_type, e)
          })
        end)

      # queue the other respondents:
      contacts_queue =
        respondents
        |> Enum.slice(5..9)
        |> Enum.reduce(:pqueue.new(), fn e, a ->
          case channel_type do
            "ivr" -> :pqueue.in([1, {e, "secret", nil, nil}], 2, a)
            "sms" -> :pqueue.in([1, {e, "secret", []}], 2, a)
          end
        end)

      state = %Ask.Runtime.ChannelBrokerState{
        channel_id: channel.id,
        runtime_channel: test_channel,
        capacity: @channel_capacity,
        active_contacts: active_contacts,
        contacts_queue: contacts_queue,
        config: Config.channel_broker_config()
      }

      %{state: state, respondents: respondents, channel: channel}
    end

    test "deactivates failed respondents" do
      %{state: state, respondents: respondents} = start_survey("ivr")

      # fail some respondents:
      Enum.at(respondents, 1) |> Respondent.changeset(%{state: :failed}) |> Repo.update!()
      Enum.at(respondents, 3) |> Respondent.changeset(%{state: :failed}) |> Repo.update!()
      Enum.at(respondents, 4) |> Respondent.changeset(%{state: :failed}) |> Repo.update!()

      # run:
      {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage, "ivr"}, state)

      # it removed failed respondents (1, 3, 4) and activated queued ones (5, 6, 7):
      assert [
               Enum.at(respondents, 0).id,
               Enum.at(respondents, 2).id,
               Enum.at(respondents, 5).id,
               Enum.at(respondents, 6).id,
               Enum.at(respondents, 7).id
             ] == Map.keys(new_state.active_contacts)
    end

    test "asks verboice for actual state of long idle contacts" do
      %{state: state, respondents: respondents} = start_survey("ivr")

      # travel to the future (within allowed contact idle time):
      time_passes(minutes: trunc(state.config.gc_active_idle_minutes / 2))
      {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage, "ivr"}, state)
      assert new_state.active_contacts == state.active_contacts

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
        {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage, "ivr"}, state)

        # it asked verboice for call state (all calls are long idle in this test case):
        assert_called_exactly(Ask.Runtime.Channel.message_inactive?(:_, :_), @channel_capacity)

        # it removed inactive respondents (0, 1, 3) and activated queued ones (5, 6, 7):
        assert [
                 Enum.at(respondents, 2).id,
                 Enum.at(respondents, 4).id,
                 Enum.at(respondents, 5).id,
                 Enum.at(respondents, 6).id,
                 Enum.at(respondents, 7).id
               ] == Map.keys(new_state.active_contacts)
      end
    end

    test "asks nuntium for actual state of long idle contacts" do
      %{state: state, respondents: respondents} = start_survey("sms")

      # travel to the future (within allowed contact idle time):
      time_passes(minutes: trunc(state.config.gc_active_idle_minutes / 2))
      {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage, "sms"}, state)
      assert new_state.active_contacts == state.active_contacts

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
        {:noreply, new_state, _} = ChannelBroker.handle_info({:collect_garbage, "sms"}, state)

        # it asked nuntium for call state (all messages are long idle in this test case):
        assert_called_exactly(Ask.Runtime.Channel.message_inactive?(:_, :_), @channel_capacity)

        # it removed inactive respondents (0, 1, 4) and activated queued ones (5, 6, 7):
        assert [
                 Enum.at(respondents, 2).id,
                 Enum.at(respondents, 3).id,
                 Enum.at(respondents, 5).id,
                 Enum.at(respondents, 6).id,
                 Enum.at(respondents, 7).id
               ] == Map.keys(new_state.active_contacts)
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

  defp assert_sent_smss(respondents, test_channel) do
    Enum.each(respondents, fn %{id: id} ->
      assert_received [:ask, ^test_channel, %{id: ^id}, _token, _reply, _channel_id]
    end)

    refute_received [:ask, ^test_channel, _respondent, _token, _reply, _channel_id]
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
end
