defmodule Ask.MobileSurveyController do
  alias Ask.Runtime.{Broker, Reply}
  alias Ask.Respondent
  use Ask.Web, :controller

  def index(conn, %{"respondent_id" => respondent_id, "token" => token}) do
    if Respondent.token(respondent_id) == token do
      do_index(conn, respondent_id)
    else
      raise Ask.UnauthorizedError, conn: conn
    end
  end

  defp do_index(conn, respondent_id) do
    respondent = Repo.get!(Respondent, respondent_id)
    cookie_name = Respondent.mobile_web_cookie_name(respondent_id)
    respondent_cookie = respondent.mobile_web_cookie_code
    if respondent_cookie do
      request_cookie = fetch_cookies(conn).req_cookies[cookie_name]
      if request_cookie == respondent_cookie do
        render_index(conn, respondent_id)
      else
        raise Ask.UnauthorizedError, conn: conn
      end
    else
      cookie_value = Ecto.UUID.generate

      respondent
      |> Respondent.changeset(%{mobile_web_cookie_code: cookie_value})
      |> Repo.update!

      conn
      |> put_resp_cookie(cookie_name, cookie_value)
      |> render_index(respondent_id)
    end
  end

  defp render_index(conn, respondent_id) do
    conn
    |> put_layout({Ask.LayoutView, "mobile_survey.html"})
    |> render("index.html", respondent_id: respondent_id)
  end

  def get_step(conn, %{"respondent_id" => respondent_id}) do
    sync_step(conn, respondent_id, :answer)
  end

  def send_reply(conn, %{"respondent_id" => respondent_id, "value" => value}) do
    sync_step(conn, respondent_id, {:reply, value})
  end

  defp sync_step(conn, respondent_id, value) do
    respondent = Repo.get!(Respondent, respondent_id)

    step =
      if respondent.state in ["pending", "active", "stalled"] do
        case Broker.sync_step(respondent, value) do
          {:reply, reply} ->
            reply |> Reply.steps() |> hd
          {:end, {:reply, reply}} ->
            reply |> Reply.steps() |> hd
          :end ->
            end_step()
        end
      else
        end_step()
      end

    render(conn, "show_step.json", step: step)
  end

  defp end_step do
    %{
      type: "explanation",
      prompts: ["The survey has ended"],
      title: "The survey has ended",
    }
  end
end
