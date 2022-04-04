defmodule Ask.Runtime.NuntiumChannelTest do
  use Ask.ConnCase
  use Ask.DummySteps

  alias Ask.Respondent
  alias Ask.Runtime.{NuntiumChannel, ReplyHelper, SurveyStub}

  require Ask.Runtime.ReplyHelper

  setup %{conn: conn} do
    GenServer.start_link(SurveyStub, [], name: SurveyStub.server_ref())

    respondent =
      insert(:respondent,
        phone_number: "123 456",
        sanitized_phone_number: "123456",
        canonical_phone_number: "123456",
        state: "active",
        session: %{"current_mode" => %{"mode" => "sms"}}
      )

    {:ok, conn: conn, respondent: respondent}
  end

  test "callback with :prompts", %{conn: conn, respondent: respondent} do
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
        %{"channel" => "chan1", "from" => "sms://123456", "body" => "yes"},
        SurveyStub
      )

    assert [
             %{"to" => "sms://123456", "body" => "Hello!", "step_title" => "Hello!"},
             %{
               "to" => "sms://123456",
               "body" => "Do you exercise?",
               "step_title" => "Do you exercise?"
             }
           ] = json_response(conn, 200)

    assert Repo.get(Respondent, respondent.id).stats == %Ask.Stats{
             total_received_sms: 1,
             total_sent_sms: 2
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
        %{"channel" => "chan1", "from" => "sms://123456", "body" => "yes"},
        SurveyStub
      )

    assert json_response(conn, 200) == []

    assert Repo.get(Respondent, respondent.id).stats == %Ask.Stats{
             total_received_sms: 1,
             total_sent_sms: 0
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
        %{"channel" => "chan1", "from" => "sms://123456", "body" => "yes"},
        SurveyStub
      )

    assert [%{"body" => "Bye!", "to" => "sms://123456", "step_title" => "Quota completed"}] =
             json_response(conn, 200)

    assert Repo.get(Respondent, respondent.id).stats == %Ask.Stats{
             total_received_sms: 1,
             total_sent_sms: 1
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
    NuntiumChannel.update_stats(respondent, ReplyHelper.multiple(["Hello!", "Do you exercise?"]))

    assert Repo.get(Respondent, respondent.id).stats == %Ask.Stats{
             total_received_sms: 1,
             total_sent_sms: 2
           }
  end

  test "callback ignored if not respondent's current mode", %{conn: conn, respondent: respondent} do
    respondent
    |> Respondent.changeset(%{session: %{"current_mode" => %{"mode" => "ivr"}}})
    |> Repo.update()

    conn =
      NuntiumChannel.callback(
        conn,
        %{"channel" => "foo", "from" => "sms://123456", "body" => "yes"},
        SurveyStub
      )

    assert [] = json_response(conn, 200)
  end

  @channel_foo %{"name" => "foo"}
  @channel_bar %{"name" => "bar"}
  @base_url "http://test.com"

  describe "channel sync" do
    test "create channels" do
      user = insert(:user)
      user_id = user.id
      account = "test_account"
      nuntium_channels = [{account, @channel_foo}, {account, @channel_bar}]
      NuntiumChannel.sync_channels(user_id, @base_url, nuntium_channels)
      channels = Ask.Channel |> order_by([c], c.name) |> Repo.all()

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
    test "create channel" do
      user = insert(:user)
      user_id = user.id

      NuntiumChannel.create_channel(
        user,
        @base_url,
        Map.put(@channel_foo, "account", "test_account")
      )

      channels = Ask.Channel |> Repo.all()

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
