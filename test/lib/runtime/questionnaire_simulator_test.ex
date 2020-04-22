defmodule QuestionnaireSimulatorTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  import Ask.StepBuilder
  alias Ask.Runtime.QuestionnaireSimulator
  alias Ask.{Questionnaire, Repo}

  setup do
    project = insert(:project)
    QuestionnaireSimulator.start_link()
    {:ok, project: project}
  end

  def questionnaire_with_steps(steps) do
    insert(:questionnaire, steps: steps)
    |> Questionnaire.changeset(%{settings: %{"thank_you_message" => %{"en" => %{"sms" => "Thank you for taking the survey"}}}})
    |> Repo.update!
  end

  test "simple case", %{project: project} do
    quiz = questionnaire_with_steps(@dummy_steps)
    %{id: respondent_id, disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.start_simulation(project, quiz)
    assert "queued" == disposition
    assert [%{body: "Do you smoke? Reply 1 for YES, 2 for NO", title: "Do you smoke?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")
    assert "started" == disposition
    assert [%{body: "Do you exercise? Reply 1 for YES, 2 for NO", title: "Do you exercise"}] == reply

    QuestionnaireSimulator.get_respondent_status(respondent_id) |> IO.inspect(label: "Respondent status")

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
    assert "started" == disposition
    assert [%{body: "Which is the second perfect number??", title: "Which is the second perfect number?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "7")
    assert "started" == disposition
    assert [%{body: "What's the number of this question??", title: "What's the number of this question?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "4")
    assert "completed" == disposition
    assert [%{body: "Thank you for taking the survey", title: "What's the number of this question?"}] == reply
  end

end
