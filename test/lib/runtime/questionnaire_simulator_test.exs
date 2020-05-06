defmodule QuestionnaireSimulatorTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.{QuestionnaireSimulator, QuestionnaireSimulatorStore}
  alias Ask.{Questionnaire, Repo, Simulation}

  setup do
    project = insert(:project)
    QuestionnaireSimulatorStore.start_link()
    {:ok, project: project}
  end

  def questionnaire_with_steps(steps) do
    insert(:questionnaire, steps: steps)
    |> Questionnaire.changeset(%{settings: %{"thank_you_message" => %{"en" => %{"sms" => "Thank you for taking the survey"}}, "error_message" => %{"en" => %{"sms" => "Sorry, that was not a valid response"}}}})
    |> Repo.update!
  end

  describe "simulation messages_history field" do
    test "simple case", %{project: project} do
      quiz = questionnaire_with_steps(@dummy_steps)

      assert_dummy_steps(project, quiz)
    end

    test "with partial flag", %{project: project} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.with_interim_partial_flag)
      %{respondent_id: respondent_id, disposition: disposition, messages_history: messages, simulation_status: status} = QuestionnaireSimulator.start_simulation(project, quiz)
      assert "contacted" == disposition
      assert  "Do you smoke? Reply 1 for YES, 2 for NO" == List.last(messages).body
      assert Simulation.Status.active == status

      %{disposition: disposition, messages_history: messages} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")
      assert "started" == disposition
      assert  "Do you exercise? Reply 1 for YES, 2 for NO" == List.last(messages).body

      %{disposition: disposition, messages_history: messages} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
      assert "interim partial" == disposition
      assert  "Is this the last question?" == List.last(messages).body

      %{disposition: disposition, messages_history: messages, simulation_status: status} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")
      assert "completed" == disposition
      assert  "Thank you for taking the survey" == List.last(messages).body
      assert Simulation.Status.ended == status
    end

    test "should maintain all respondent responses even if aren't valid", %{project: project} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id, messages_history: messages} = QuestionnaireSimulator.start_simulation(project, quiz)
      assert  "Do you smoke? Reply 1 for YES, 2 for NO" == List.last(messages).body
      %{messages_history: messages} = QuestionnaireSimulator.process_respondent_response(respondent_id, "perhaps")
      [_question, response, error_message, re_question] = messages
      assert response.body == "perhaps"
      assert error_message.body == "Sorry, that was not a valid response"
      assert re_question.body == "Do you smoke? Reply 1 for YES, 2 for NO"
    end
  end

  describe "simulation submissions field" do

    test "should include the explanation steps", %{project: project} do
      steps = SimulatorQuestionnaireSteps.with_explanation_first_step
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = QuestionnaireSimulator.start_simulation(project, quiz)
      %{submissions: submissions} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")

      [first, second, third] = steps
      expected_submissions = [
        %{step: first["title"], id: first["id"]},
        %{step: second["title"], id: second["id"], response: "No"},
        %{step: third["title"], id: third["id"]},
      ]
      assert expected_submissions == submissions
    end

    test "should indicate as response the valid-parsed responses", %{project: project} do
      steps = @dummy_steps
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = QuestionnaireSimulator.start_simulation(project, quiz)
      %{submissions: submissions} = QuestionnaireSimulator.process_respondent_response(respondent_id, "1") # 1 is a yes response
      first = hd(steps)
      assert [%{step: first["title"], id: first["id"], response: "Yes"}] == submissions
    end

    test "should not include the non-valid responses (since the step is not completed)", %{project: project} do
      steps = @dummy_steps
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = QuestionnaireSimulator.start_simulation(project, quiz)
      %{submissions: submissions} = QuestionnaireSimulator.process_respondent_response(respondent_id, "perhaps")
      assert [] == submissions
    end
  end

  test "process_respondent_response of non-present simulation should return a SimulationStep with status: expired" do
    respondent_id =  Ecto.UUID.generate()
    %{simulation_status: status, respondent_id: rid} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")
    assert Ask.Simulation.Status.expired == status
    assert respondent_id == rid
  end

  test "the simulator supports questionnaires with section", %{project: project} do
    quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.one_section_dummy_steps)
    # The flow should be the same as without section
    assert_dummy_steps(project, quiz)
  end

  test "the simulator supports questionnaires with multiple sections", %{project: project} do
    quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.two_sections_dummy_steps)
    # The flow should be the same as without sections since are not randomized
    assert_dummy_steps(project, quiz)
  end

  test "start_simulation with ivr mode returns :not_implemented", %{project: project} do
    quiz = questionnaire_with_steps(@dummy_steps)
    assert :not_implemented == QuestionnaireSimulator.start_simulation(project, quiz, "ivr")
  end

  test "start_simulation with mobile_web mode returns :not_implemented", %{project: project} do
    quiz = questionnaire_with_steps(@dummy_steps)
    assert :not_implemented == QuestionnaireSimulator.start_simulation(project, quiz, "mobile-web")
  end

  describe "stop messages ends the simulation" do
    test "if stop message on contacted disposition, then final disposition is 'refused'", %{project: project} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id, disposition: starting_disposition} = QuestionnaireSimulator.start_simulation(project, quiz)
      assert "contacted" == starting_disposition

      %{simulation_status: status, disposition: disposition} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Stop")

      assert Simulation.Status.ended == status
      assert "refused" == disposition
    end

    test "if stop message on started disposition, then final disposition is 'breakoff'", %{project: project} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id} = QuestionnaireSimulator.start_simulation(project, quiz)
      %{disposition: previous_disposition} = QuestionnaireSimulator.process_respondent_response(respondent_id, "No")

      assert "started" == previous_disposition

      %{simulation_status: status, disposition: disposition} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Stop")

      assert Simulation.Status.ended == status
      assert "breakoff" == disposition
    end

    test "if stop message on interim-partial disposition, then final disposition is 'breakoff'", %{project: project} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.with_interim_partial_flag)
      %{respondent_id: respondent_id} = QuestionnaireSimulator.start_simulation(project, quiz)
      QuestionnaireSimulator.process_respondent_response(respondent_id, "No")
      %{disposition: previous_disposition} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Yes")

      assert "interim partial" == previous_disposition

      %{simulation_status: status, disposition: disposition} = QuestionnaireSimulator.process_respondent_response(respondent_id, "Stop")

      assert Simulation.Status.ended == status
      assert "partial" == disposition
    end
  end

  defp assert_dummy_steps(project, quiz) do
    %{respondent_id: respondent_id, disposition: disposition, messages_history: messages, simulation_status: status} = QuestionnaireSimulator.start_simulation(project, quiz)
    assert "contacted" == disposition
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
end


defmodule SimulatorQuestionnaireSteps do
  import Ask.StepBuilder
  use Ask.DummySteps

  def one_section_dummy_steps, do: [section(id: "Section1", title: "First Section", randomize: false, steps: @dummy_steps)]

  def two_sections_dummy_steps do
    steps = @dummy_steps
    [section(id: "Section1", title: "First Section", randomize: false, steps: steps |> Enum.take(2)), section(id: "Section2", title: "Second Section", randomize: false, steps: steps |> Enum.drop(2))]
  end

  def with_explanation_first_step, do: [
    explanation_step(
      id: Ecto.UUID.generate,
      title: "Welcome",
      prompt: prompt(
        sms: sms_prompt("Please consider taking this survey")
      ),
      skip_logic: nil
    ),
    multiple_choice_step(
      id: Ecto.UUID.generate,
      title: "Do you smoke?",
      prompt: prompt(
        sms: sms_prompt("Do you smoke? Reply 1 for YES, 2 for NO")
      ),
      store: "Smokes",
      choices: [
        choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"])),
        choice(value: "No", responses: responses(sms: ["No", "N", "2"]))
      ]
    ),
    explanation_step(
        id: Ecto.UUID.generate,
        title: "Explanation",
        prompt: prompt(
          sms: sms_prompt("Your responses will be used responsibly")
        ),
        skip_logic: nil
      )
  ]

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