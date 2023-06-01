defmodule Ask.Runtime.NuntiumChannelTest do
  use AskWeb.ConnCase
  use Ask.DummySteps
  use Ask.TestHelpers

  alias Ask.Respondent

  alias Ask.Runtime.{
    NuntiumChannel,
    ReplyHelper,
    SurveyStub,
    ChannelStatusServer,
    ChannelBrokerAgent
  }

  require Ask.Runtime.ReplyHelper

  setup %{conn: conn} do
    on_exit(fn ->
      ChannelBrokerSupervisor.terminate_children()
    end)

    GenServer.start_link(SurveyStub, [], name: SurveyStub.server_ref())
    ChannelStatusServer.start_link()
    ChannelBrokerAgent.start_link()

    [_survey, _group, _test_channel, [respondent], channel] =
      create_running_survey_with_channel_and_respondents_with_options(
        mode: "sms",
        respondents_quantity: 1
      )

    broker_poll()

    # After the broker poll the respondent is active and already received 1 AO message (total_sent_sms = 1)
    respondent = Repo.get!(Respondent, respondent.id)

    {:ok, conn: conn, respondent: respondent, channel: channel}
  end

  test "callback with :prompts", %{conn: conn, respondent: respondent, channel: channel} do
    respondent_id = respondent.id

    GenServer.cast(
      SurveyStub.server_ref(),
      {:expects,
       fn
         {:sync_step, %Respondent{id: ^respondent_id}, {:reply, "yes"}, "sms"} ->
           {:reply, ReplyHelper.multiple(["Hello!", "Do you exercise?"]), respondent}
       end}
    )

    conn =
      NuntiumChannel.callback(
        conn,
        %{
          "channel" => "chan1",
          "from" => "sms://#{respondent.sanitized_phone_number}",
          "body" => "yes"
        },
        SurveyStub
      )

    channel_id = channel.id
    to = "sms://#{respondent.sanitized_phone_number}"

    assert [
             %{
               "to" => ^to,
               "body" => "Hello!",
               "step_title" => "Hello!",
               "channel_id" => ^channel_id
             },
             %{
               "to" => ^to,
               "body" => "Do you exercise?",
               "step_title" => "Do you exercise?",
               "channel_id" => ^channel_id
             }
           ] = json_response(conn, 200)

    assert Repo.get(Respondent, respondent.id).stats == %Ask.Stats{
             attempts: %{"sms" => 1},
             total_received_sms: 1,
             total_sent_sms: 3
           }
  end

  test "callback with {:end, respondent}", %{conn: conn, respondent: respondent} do
    respondent_id = respondent.id

    GenServer.cast(
      SurveyStub.server_ref(),
      {:expects,
       fn
         {:sync_step, %Respondent{id: ^respondent_id}, {:reply, "yes"}, "sms"} ->
           {:end, respondent}
       end}
    )

    conn =
      NuntiumChannel.callback(
        conn,
        %{
          "channel" => "chan1",
          "from" => "sms://#{respondent.sanitized_phone_number}",
          "body" => "yes"
        },
        SurveyStub
      )

    assert json_response(conn, 200) == []

    assert Repo.get(Respondent, respondent.id).stats == %Ask.Stats{
             attempts: %{"sms" => 1},
             total_received_sms: 1,
             total_sent_sms: 1
           }
  end

  test "callback with :end, :prompt", %{conn: conn, respondent: respondent} do
    respondent_id = respondent.id

    GenServer.cast(
      SurveyStub.server_ref(),
      {:expects,
       fn
         {:sync_step, %Respondent{id: ^respondent_id}, {:reply, "yes"}, "sms"} ->
           {:end, {:reply, ReplyHelper.quota_completed("Bye!")}, respondent}
       end}
    )

    conn =
      NuntiumChannel.callback(
        conn,
        %{
          "channel" => "chan1",
          "from" => "sms://#{respondent.sanitized_phone_number}",
          "body" => "yes"
        },
        SurveyStub
      )

    to = "sms://#{respondent.sanitized_phone_number}"

    assert [%{"body" => "Bye!", "to" => ^to, "step_title" => "Quota completed"}] =
             json_response(conn, 200)

    assert Repo.get(Respondent, respondent.id).stats == %Ask.Stats{
             attempts: %{"sms" => 1},
             total_received_sms: 1,
             total_sent_sms: 2
           }
  end

  test "callback respondent not found", %{conn: conn} do
    conn =
      NuntiumChannel.callback(
        conn,
        %{"channel" => "chan1", "from" => "sms://456", "body" => "yes"},
        SurveyStub
      )

    assert json_response(conn, 200) == []
  end

  test "unknown callback is replied with OK", %{conn: conn} do
    conn =
      NuntiumChannel.callback(conn, %{
        "channel" => "foo",
        "guid" => Ecto.UUID.generate(),
        "state" => "delivered"
      })

    assert response(conn, 200) == "OK"
  end

  test "status callback for unknown respondent is replied with OK", %{conn: conn} do
    conn =
      NuntiumChannel.callback(conn, %{
        "path" => ["status"],
        "respondent_id" => "-1",
        "state" => "delivered"
      })

    assert response(conn, 200) == ""
  end

  test "update stats", %{respondent: respondent} do
    NuntiumChannel.update_stats(
      respondent.id,
      ReplyHelper.multiple(["Hello!", "Do you exercise?"])
    )

    assert Repo.get(Respondent, respondent.id).stats == %Ask.Stats{
             total_received_sms: 1,
             total_sent_sms: 3,
             attempts: %{"sms" => 1}
           }
  end

  test "callback ignored if not respondent's current mode", %{conn: conn, respondent: respondent} do
    respondent
    |> Respondent.changeset(%{session: %{"current_mode" => %{"mode" => "ivr"}}})
    |> Repo.update()

    conn =
      NuntiumChannel.callback(
        conn,
        %{
          "channel" => "foo",
          "from" => "sms://#{respondent.sanitized_phone_number}",
          "body" => "yes"
        },
        SurveyStub
      )

    assert [] = json_response(conn, 200)
  end

  @channel_foo %{"name" => "foo"}
  @channel_bar %{"name" => "bar"}
  @base_url "http://test.com"

  describe "channel sync" do
    test "create channels", %{channel: %{id: channel_id} = _channel} do
      user = insert(:user)
      user_id = user.id
      account = "test_account"
      nuntium_channels = [{account, @channel_foo}, {account, @channel_bar}]
      NuntiumChannel.sync_channels(user_id, @base_url, nuntium_channels)

      channels =
        Ask.Channel |> order_by([c], c.name) |> where([c], c.id != ^channel_id) |> Repo.all()

      assert [
               %Ask.Channel{
                 user_id: ^user_id,
                 base_url: @base_url,
                 provider: "nuntium",
                 type: "sms",
                 name: "bar - test_account",
                 settings: %{
                   "nuntium_account" => "test_account",
                   "nuntium_channel" => "bar"
                 }
               },
               %Ask.Channel{
                 user_id: ^user_id,
                 base_url: @base_url,
                 provider: "nuntium",
                 type: "sms",
                 name: "foo - test_account",
                 settings: %{
                   "nuntium_account" => "test_account",
                   "nuntium_channel" => "foo"
                 }
               }
             ] = channels
    end
  end

  describe "create channel" do
    test "create channel", %{channel: %{id: channel_id} = _channel} do
      user = insert(:user)
      user_id = user.id

      NuntiumChannel.create_channel(
        user,
        @base_url,
        Map.put(@channel_foo, "account", "test_account")
      )

      channels = Ask.Channel |> where([c], c.id != ^channel_id) |> Repo.all()

      assert [
               %Ask.Channel{
                 user_id: ^user_id,
                 provider: "nuntium",
                 base_url: @base_url,
                 type: "sms",
                 name: "foo - test_account",
                 settings: %{"nuntium_channel" => "foo", "nuntium_account" => "test_account"}
               }
             ] = channels
    end
  end

  test "check status" do
    assert NuntiumChannel.check_status(%{"enabled" => true, "connected" => true}) == :up
    assert NuntiumChannel.check_status(%{"enabled" => true, "connected" => false}) == {:down, []}
    assert NuntiumChannel.check_status(%{"enabled" => true}) == :up
  end
end
