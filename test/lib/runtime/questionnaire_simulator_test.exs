defmodule QuestionnaireSimulatorTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.{QuestionnaireSimulator, QuestionnaireSimulatorStore}
  alias Ask.{Questionnaire, Repo}

  setup do
    project = insert(:project)
    QuestionnaireSimulatorStore.start_link()
    {:ok, project: project}
  end

  def questionnaire_with_steps(steps) do
    insert(:questionnaire, steps: steps)
    |> Questionnaire.changeset(%{settings: %{"thank_you_message" => %{"en" => %{"sms" => "Thank you for taking the survey"}}}})
    |> Repo.update!
  end

  test "simple case", %{project: project} do
    quiz = questionnaire_with_steps(@dummy_steps)
    %{respondent_id: respondent_id, disposition: disposition, messages_history: messages, simulation_status: status} = QuestionnaireSimulator.start_simulation(project, quiz)
    assert "queued" == disposition #TODO: is ok queued? should be contacted?
    assert "Do you smoke? Reply 1 for YES, 2 for NO" == List.last(messages).body
    assert Ask.Simulation.Status.active == status

    %{disposition: disposition, messages_history: messages} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")
    assert "started" == disposition
    assert "Do you exercise? Reply 1 for YES, 2 for NO" == List.last(messages).body

    %{disposition: disposition, messages_history: messages} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
    assert "started" == disposition
    assert  "Which is the second perfect number??" == List.last(messages).body

    %{disposition: disposition, messages_history: messages} = QuestionnaireSimulator.process_respondent_response(respondent_id, "7")
    assert "started" == disposition
    assert  "What's the number of this question??" == List.last(messages).body

    %{disposition: disposition, messages_history: messages, simulation_status: status} = QuestionnaireSimulator.process_respondent_response(respondent_id, "4")
    assert "completed" == disposition
    assert "Thank you for taking the survey" == List.last(messages).body
    assert Ask.Simulation.Status.ended == status
  end

  test "with partial flag", %{project: project} do
    quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.with_interim_partial_flag)
    %{respondent_id: respondent_id, disposition: disposition, messages_history: messages, simulation_status: status} = QuestionnaireSimulator.start_simulation(project, quiz)
    assert "queued" == disposition #TODO: is ok queued? should be contacted?
    assert  "Do you smoke? Reply 1 for YES, 2 for NO" == List.last(messages).body
    assert Ask.Simulation.Status.active == status

    %{disposition: disposition, messages_history: messages} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")
    assert "started" == disposition
    assert  "Do you exercise? Reply 1 for YES, 2 for NO" == List.last(messages).body

    %{disposition: disposition, messages_history: messages} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
    assert "interim partial" == disposition
    assert  "Is this the last question?" == List.last(messages).body

    %{disposition: disposition, messages_history: messages, simulation_status: status} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
    assert "completed" == disposition
    assert  "Thank you for taking the survey" == List.last(messages).body
    assert Ask.Simulation.Status.ended == status
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