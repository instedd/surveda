defmodule AskWeb.MobileSurveyController do
  alias Ask.Runtime.{Survey, Reply}
  alias Ask.Respondent
  use AskWeb, :controller

  @default_title "InSTEDD Surveda"

  def index(conn, %{"respondent_id" => respondent_id, "token" => token}) do
    respondent = Respondent |> Repo.get(respondent_id)

    if !respondent do
      conn
      |> put_status(:not_found)
      |> put_layout({AskWeb.LayoutView, "mobile_survey.html"})
      |> render("404.html",
        title: @default_title,
        mobile_web_intro_message: "mobile_web_intro_message"
      )
    else
      color_style = color_style_for(respondent_id)

      authorize(conn, respondent_id, token, fn ->
        render_index(conn, respondent, token, color_style)
      end)
    end
  end

  defp render_index(conn, respondent, token, color_style) do
    questionnaire =
      respondent
      |> assoc(:questionnaire)
      |> Repo.one()

    default_language = questionnaire.default_language

    {title, mobile_web_intro_message} =
      case questionnaire do
        %{
          settings: %{
            "title" => %{^default_language => some_title},
            "mobile_web_intro_message" => intro_message
          }
        } ->
          {some_title, intro_message}

        _ ->
          {"Your survey", "Go ahead"}
      end

    conn
    |> put_layout({AskWeb.LayoutView, "mobile_survey.html"})
    |> render("index.html",
      respondent_id: respondent.id,
      token: token,
      color_style: color_style,
      title: title,
      mobile_web_intro_message: mobile_web_intro_message
    )
  end

  defp color_style_for(respondent_id) do
    (Respondent
     |> Repo.get(respondent_id)
     |> Repo.preload(:questionnaire)).questionnaire.settings["mobile_web_color_style"]
  end

  defp primary_color_for(color_style) do
    case color_style do
      nil ->
        ''

      color_style ->
        color_style["primary_color"]
    end
  end

  def get_step(conn, %{"respondent_id" => respondent_id, "token" => token}) do
    authorize(conn, respondent_id, token, fn ->
      # Cookies disabled for now, see #2241
      # check_cookie(conn, respondent_id, fn conn ->
      sync_step(conn, respondent_id, :answer)
      # end)
    end)
  end

  def send_reply(conn, %{
        "respondent_id" => respondent_id,
        "token" => token,
        "value" => value,
        "step_id" => step_id
      }) do
    authorize(conn, respondent_id, token, fn ->
      # Cookies disabled for now, see #2241
      # check_cookie(conn, respondent_id, fn conn ->
      sync_step(conn, respondent_id, {:reply_with_step_id, value, step_id})
      # end)
    end)
  end

  defp sync_step(conn, respondent_id, value) do
    {step, progress, error_message} =
      Respondent.with_lock(
        respondent_id,
        fn respondent ->
          survey = Repo.preload(respondent, :survey).survey

          cond do
            survey.state == :terminated ->
              questionnaires = Repo.preload(survey, :questionnaires).questionnaires
              questionnaire = Enum.random(questionnaires)

              msg =
                questionnaire.settings["mobile_web_survey_is_over_message"] ||
                  "The survey is over"

              {end_step(msg), end_progress(), nil}

            respondent.state in [:pending, :active, :rejected] ->
              case Survey.sync_step(respondent, value, "mobileweb") do
                {:reply, reply, _} ->
                  {Reply.first_step(reply), Reply.progress(reply), reply.error_message}

                {:end, {:reply, reply}, _} ->
                  {Reply.first_step(reply), Reply.progress(reply), reply.error_message}

                {:end, _} ->
                  {end_step(), end_progress(), nil}
              end

            true ->
              {end_step(fetch_survey_already_taken_message(respondent)), end_progress(), nil}
          end
        end,
        &Repo.preload(&1, :questionnaire)
      )

    json(conn, %{
      step: step,
      progress: progress,
      error_message: error_message
    })
  end

  defp end_step(msg \\ "The survey has ended") do
    %{
      type: "end",
      prompts: [msg],
      title: msg
    }
  end

  defp end_progress do
    100.0
  end

  defp fetch_survey_already_taken_message(respondent) do
    language = respondent.language || respondent.questionnaire.default_language

    (respondent.questionnaire.settings["survey_already_taken_message"] || %{})[language] ||
      "You already took this survey"
  end

  defp authorize(conn, respondent_id, token, success_fn) do
    if Respondent.token(respondent_id) == token do
      success_fn.()
    else
      color_style = color_style_for(respondent_id)

      primary_color = primary_color_for(color_style)

      conn
      |> put_status(403)
      |> put_layout({AskWeb.LayoutView, "mobile_survey.html"})
      |> render("unauthorized.html",
        header_color: primary_color,
        title: @default_title,
        mobile_web_intro_message: ""
      )
    end
  end

  # defp check_cookie(conn, respondent_id, success_fn) do
  #   respondent = Repo.get!(Respondent, respondent_id)
  #   cookie_name = Respondent.mobile_web_cookie_name(respondent_id)
  #   respondent_cookie = respondent.mobile_web_cookie_code

  #   if respondent_cookie do
  #     request_cookie = fetch_cookies(conn).req_cookies[cookie_name]

  #     if request_cookie == respondent_cookie do
  #       success_fn.(conn)
  #     else
  #       raise AskWeb.UnauthorizedError
  #     end
  #   else
  #     cookie_value = Ecto.UUID.generate()

  #     respondent
  #     |> Respondent.changeset(%{mobile_web_cookie_code: cookie_value})
  #     |> Repo.update!()

  #     conn =
  #       conn
  #       |> put_resp_cookie(cookie_name, cookie_value)

  #     success_fn.(conn)
  #   end
  # end

  def unauthorized_error(conn, %{"id" => respondent_id}) do
    color_style = color_style_for(respondent_id)
    primary_color = primary_color_for(color_style)

    conn
    |> put_status(401)
    |> put_layout({AskWeb.LayoutView, "mobile_survey.html"})
    |> render("unauthorized.html",
      header_color: primary_color,
      title: @default_title,
      mobile_web_intro_message: ""
    )
  end
end
