defmodule QuestionnaireSimulatorTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
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
    assert "queued" == disposition #TODO: is ok queued? should be contacted?
    assert [%{body: "Do you smoke? Reply 1 for YES, 2 for NO", title: "Do you smoke?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")
    assert "started" == disposition
    assert [%{body: "Do you exercise? Reply 1 for YES, 2 for NO", title: "Do you exercise"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
    assert "started" == disposition
    assert [%{body: "Which is the second perfect number??", title: "Which is the second perfect number?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "7")
    assert "started" == disposition
    assert [%{body: "What's the number of this question??", title: "What's the number of this question?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "4")
    assert "completed" == disposition
    assert [%{body: "Thank you for taking the survey", title: "Thank you"}] == reply
  end

  test "with partial flag", %{project: project} do
    quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.with_interim_partial_flag)
    %{id: respondent_id, disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.start_simulation(project, quiz)
    assert "queued" == disposition #TODO: is ok queued? should be contacted?
    assert [%{body: "Do you smoke? Reply 1 for YES, 2 for NO", title: "Do you smoke?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")
    assert "started" == disposition
    assert [%{body: "Do you exercise? Reply 1 for YES, 2 for NO", title: "Do you exercise?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
    assert "interim partial" == disposition
    assert [%{body: "Is this the last question?", title: "Is this the last question?"}] == reply

    %{disposition: disposition, reply_messages: reply} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
    assert "completed" == disposition
    assert [%{body: "Thank you for taking the survey", title: "Thank you"}] == reply
  end

end

defmodule SimulatorQuestionnaireSteps do
  import Ask.StepBuilder

  def with_interim_partial_flag(), do: [
    multiple_choice_step(
      id: Ecto.UUID.generate,
      title: "Do you smoke?",
      prompt: prompt(
        sms: sms_prompt("Do you smoke? Reply 1 for YES, 2 for NO"),
        ivr: tts_prompt("Do you smoke? Press 8 for YES, 9 for NO")
      ),
      store: "Smokes",
      choices: [
        choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["8"])),
        choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["9"]))
      ]
    ),
    multiple_choice_step(
      id: "bbb",
      title: "Do you exercise?",
      prompt: prompt(
        sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO"),
        ivr: tts_prompt("Do you exercise? Reply 1 for YES, 2 for NO")
      ),
      store: "Exercises",
      choices: [
        choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
        choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
      ]
    ),
    flag_step(
      id: "aaa",
      title: "Let there be rock",
      disposition: "interim partial"
    ),
    multiple_choice_step(
      id: "eee",
      title: "Is this the last question?",
      prompt: prompt(
        sms: sms_prompt("Is this the last question?"),
        ivr: tts_prompt("Is this the last question?")
      ),
      store: "Last",
      choices: [
        choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"])),
        choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"]))
      ]
    )
  ]
end