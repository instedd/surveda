defmodule QuestionnaireSimulatorTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.{QuestionnaireSimulator, QuestionnaireSimulatorStore}
  alias Ask.{Questionnaire, Repo, Simulation}
  alias Ask.QuestionnaireRelevantSteps

  setup do
    project = insert(:project)
    QuestionnaireSimulatorStore.start_link()
    start_simulation = fn quiz ->
      {:ok, simulation} = QuestionnaireSimulator.start_simulation(project, quiz, "sms")
      simulation
    end
    {:ok, project: project, start_simulation: start_simulation}
  end

  def questionnaire_with_steps(steps, thank_you_message \\ %{"en" => %{"sms" => "Thank you for taking the survey"}}) do
    insert(:questionnaire, steps: steps, quota_completed_steps: [])
    |> Questionnaire.changeset(%{settings: %{"thank_you_message" => thank_you_message, "error_message" => %{"en" => %{"sms" => "Sorry, that was not a valid response"}}}})
    |> Repo.update!
  end

  def process_respondent_response(respondent_id, response) do
    {:ok, simulation_step} = QuestionnaireSimulator.process_respondent_response(respondent_id, response, "sms")
    simulation_step
  end

  describe "simulation messages_history field" do
    test "simple case", %{project: project} do
      quiz = questionnaire_with_steps(@dummy_steps)

      assert_dummy_steps(project, quiz)
    end

    test "with partial flag", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.with_interim_partial_flag)
      %{respondent_id: respondent_id, disposition: disposition, messages_history: messages, simulation_status: status} = start_simulation.(quiz)
      assert "contacted" == disposition
      assert  "Do you smoke? Reply 1 for YES, 2 for NO" == List.last(messages).body
      assert Simulation.Status.active == status

      %{disposition: disposition, messages_history: messages} = process_respondent_response(respondent_id, "No")
      assert "started" == disposition
      assert  "Do you exercise? Reply 1 for YES, 2 for NO" == List.last(messages).body

      %{disposition: disposition, messages_history: messages} = process_respondent_response(respondent_id, "Yes")
      assert "interim partial" == disposition
      assert  "Is this the last question?" == List.last(messages).body

      %{disposition: disposition, messages_history: messages, simulation_status: status} = process_respondent_response(respondent_id, "Yes")
      assert "completed" == disposition
      assert  "Thank you for taking the survey" == List.last(messages).body
      assert Simulation.Status.ended == status
    end

    test "should maintain all respondent responses even if aren't valid", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id, messages_history: messages} = start_simulation.(quiz)
      assert  "Do you smoke? Reply 1 for YES, 2 for NO" == List.last(messages).body
      %{messages_history: messages} = process_respondent_response(respondent_id, "perhaps")
      [_question, response, error_message, re_question] = messages
      assert response.body == "perhaps"
      assert error_message.body == "Sorry, that was not a valid response"
      assert re_question.body == "Do you smoke? Reply 1 for YES, 2 for NO"
    end
  end

  describe "simulation submissions field" do

    test "should include the explanation steps", %{start_simulation: start_simulation} do
      steps = SimulatorQuestionnaireSteps.with_explanation_first_step
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz)
      %{submissions: submissions} = process_respondent_response(respondent_id, "No")

      [first, second, third] = steps
      expected_submissions = [
        expected_submission(first),
        expected_submission(second, "No"),
        expected_submission(third)
      ]
      assert expected_submissions == submissions
    end

    test "should indicate as response the valid-parsed responses", %{start_simulation: start_simulation} do
      steps = @dummy_steps
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz)
      %{submissions: submissions} = process_respondent_response(respondent_id, "1") # 1 is a yes response
      first = hd(steps)
      assert [expected_submission(first, "Yes")] == submissions
    end

    test "should not include the non-valid responses (since the step is not completed)", %{start_simulation: start_simulation} do
      steps = @dummy_steps
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz)
      %{submissions: submissions} = process_respondent_response(respondent_id, "perhaps")
      assert [] == submissions
    end

    test "should include all the responses", %{start_simulation: start_simulation} do
      steps = @dummy_steps
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz)

      process_respondent_response(respondent_id, "1") # 1 is a yes response
      process_respondent_response(respondent_id, "Y") # Y is a yes response
      process_respondent_response(respondent_id, "7") # numeric response
      %{submissions: submissions} = process_respondent_response(respondent_id, "4") # numeric response

      [first, second, third, fourth] = steps
      expected_submissions = [
        expected_submission(first, "Yes"),
        expected_submission(second, "Yes"),
        expected_submission(third, "7"),
        expected_submission(fourth, "4")
      ]
      assert expected_submissions == submissions
    end

    test "should include all the responses even if the quiz doesn't have a thank-you-message", %{start_simulation: start_simulation} do
      steps = @dummy_steps
      quiz = questionnaire_with_steps(steps, nil)
      %{respondent_id: respondent_id} = start_simulation.(quiz)

      process_respondent_response(respondent_id, "1") # 1 is a yes response
      process_respondent_response(respondent_id, "Y") # Y is a yes response
      process_respondent_response(respondent_id, "7") # numeric response
      %{submissions: submissions} = process_respondent_response(respondent_id, "4") # numeric response

      [first, second, third, fourth] = steps
      expected_submissions = [
        expected_submission(first, "Yes"),
        expected_submission(second, "Yes"),
        expected_submission(third, "7"),
        expected_submission(fourth, "4")
      ]
      assert expected_submissions == submissions
    end
  end

  test "process_respondent_response of non-present simulation should return a SimulationStep with status: expired" do
    respondent_id =  Ecto.UUID.generate()
    %{simulation_status: status, respondent_id: rid} = process_respondent_response(respondent_id, "No")
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

  describe "simulator responses invalid_simulation" do
    test "when start_simulation with ivr mode", %{project: project} do
      quiz = questionnaire_with_steps(@dummy_steps)
      assert {:error, :invalid_simulation} == QuestionnaireSimulator.start_simulation(project, quiz, "ivr")
    end

    test "when start_simulation with sms mode but questionnaire doesn't have sms mode", %{project: project}  do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.only_ivr_steps())
             |> Questionnaire.changeset(%{modes: ["ivr"]})
             |> Repo.update!
      assert {:error, :invalid_simulation} == QuestionnaireSimulator.start_simulation(project, quiz, "sms")
    end
  end

  describe "stop messages ends the simulation" do
    test "if stop message on contacted disposition, then final disposition is 'refused'", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id, disposition: starting_disposition} = start_simulation.(quiz)
      assert "contacted" == starting_disposition

      %{simulation_status: status, disposition: disposition} = process_respondent_response(respondent_id, "Stop")

      assert Simulation.Status.ended == status
      assert "refused" == disposition
    end

    test "if stop message on started disposition, then final disposition is 'breakoff'", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz)
      %{disposition: previous_disposition} = process_respondent_response(respondent_id, "No")

      assert "started" == previous_disposition

      %{simulation_status: status, disposition: disposition} = process_respondent_response(respondent_id, "Stop")

      assert Simulation.Status.ended == status
      assert "breakoff" == disposition
    end

    test "if stop message on interim-partial disposition, then final disposition is 'breakoff'", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.with_interim_partial_flag)
      %{respondent_id: respondent_id} = start_simulation.(quiz)
      process_respondent_response(respondent_id, "No")
      %{disposition: previous_disposition} = process_respondent_response(respondent_id, "Yes")

      assert "interim partial" == previous_disposition

      %{simulation_status: status, disposition: disposition} = process_respondent_response(respondent_id, "Stop")

      assert Simulation.Status.ended == status
      assert "partial" == disposition
    end
  end

  describe "questionnaire with relevant steps" do
    test "if respondent answers min_relevant_steps, disposition should be 'interim partial'", %{start_simulation: start_simulation} do
      steps = QuestionnaireRelevantSteps.all_relevant_steps()
      quiz = questionnaire_with_steps(steps) |> Questionnaire.changeset(%{partial_relevant_config: %{"enabled" => true, "min_relevant_steps" => 2, "ignored_values" => ""}}) |> Repo.update!
      %{respondent_id: respondent_id, disposition: disposition} = start_simulation.(quiz)
      assert "contacted" == disposition

      %{disposition: disposition} = process_respondent_response(respondent_id, "No")
      assert "started" == disposition

      %{disposition: disposition} = process_respondent_response(respondent_id, "Yes")
      assert "interim partial" == disposition
    end

    test "once the respondent reaches 'interim partial', simulation should return such disposition until completes the survey", %{start_simulation: start_simulation} do
      steps = QuestionnaireRelevantSteps.all_relevant_steps()
      quiz = questionnaire_with_steps(steps) |> Questionnaire.changeset(%{partial_relevant_config: %{"enabled" => true, "min_relevant_steps" => 2, "ignored_values" => ""}}) |> Repo.update!
      %{respondent_id: respondent_id, disposition: disposition} = start_simulation.(quiz)
      assert "contacted" == disposition

      %{disposition: disposition} = process_respondent_response(respondent_id, "No")
      assert "started" == disposition

      %{disposition: disposition} = process_respondent_response(respondent_id, "Yes")
      assert "interim partial" == disposition

      %{disposition: disposition} = process_respondent_response(respondent_id, "7")
      assert "interim partial" == disposition

      %{disposition: disposition, simulation_status: status} = process_respondent_response(respondent_id, "4")
      assert "completed" == disposition
      assert Simulation.Status.ended == status
    end

    test "if respondent answer min_relevant_steps, even of different sections, disposition should be 'interim partial'", %{start_simulation: start_simulation} do
      steps = QuestionnaireRelevantSteps.relevant_steps_in_multiple_sections()
      quiz = questionnaire_with_steps(steps) |> Questionnaire.changeset(%{partial_relevant_config: %{"enabled" => true, "min_relevant_steps" => 2, "ignored_values" => ""}}) |> Repo.update!
      %{respondent_id: respondent_id, disposition: disposition} = start_simulation.(quiz)
      assert "contacted" == disposition

      %{disposition: disposition} = process_respondent_response(respondent_id, "No") # First relevant
      assert "started" == disposition

      %{disposition: disposition} = process_respondent_response(respondent_id, "5")
      assert "started" == disposition

      %{disposition: disposition} = process_respondent_response(respondent_id, "No") # Second relevant, in different section
      assert "interim partial" == disposition
    end
  end

  describe "questionnaire field" do
    test "should be included in start_simulation", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      assert %{questionnaire: _quex} = start_simulation.(quiz)
    end

    test "should not be included in process_respondent_response", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz)
      assert %{questionnaire: nil} = process_respondent_response(respondent_id, "No")
    end

    test "if quiz doesn't have sections, steps should be in the same order", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{questionnaire: quex} = start_simulation.(quiz)
      assert quiz.steps == quex.steps
    end

    test "if quiz has sections but not randomized, steps should be in the same order", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.two_sections_dummy_steps)
      %{questionnaire: quex} = start_simulation.(quiz)
      assert quiz.steps == quex.steps
    end

    test "if quiz has randomized sections, steps should be in the order it will be send to respondent", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.four_sections_randomized_dummy_steps)
      %{section_order: section_order, questionnaire: quex} = randomized_section_order(quiz, start_simulation)

      assert quex.steps != quiz.steps
      assert length(quex.steps) == length(quiz.steps)
      quex.steps |> Enum.with_index |> Enum.each(fn {step, index} ->
        original_step_index = section_order |> Enum.at(index)
        assert step == (quiz.steps |> Enum.at(original_step_index))
      end)
    end
  end

  # Starts different simulations until one has a shuffled section order
  defp randomized_section_order(quiz, start_simulation) do
    %{questionnaire: quex, respondent_id: respondent_id} = start_simulation.(quiz)
    %{section_order: section_order} = Ask.Runtime.QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    if section_order == Enum.sort(section_order) do
      # Sections where not shuffled
      randomized_section_order(quiz, start_simulation)
    else
      %{section_order: section_order, questionnaire: quex}
    end
  end

  defp assert_dummy_steps(project, quiz) do
    {:ok, %{respondent_id: respondent_id, disposition: disposition, messages_history: messages, simulation_status: status, current_step: current_step}} = QuestionnaireSimulator.start_simulation(project, quiz, "sms")
    [first, second, third, fourth] = quiz |> Questionnaire.all_steps|> Enum.map(fn step -> step["id"] end)
    assert "contacted" == disposition
    assert "Do you smoke? Reply 1 for YES, 2 for NO" == List.last(messages).body
    assert current_step == first
    assert Ask.Simulation.Status.active == status

    %{disposition: disposition, messages_history: messages, current_step: current_step} = process_respondent_response(respondent_id, "No")
    assert "started" == disposition
    assert "Do you exercise? Reply 1 for YES, 2 for NO" == List.last(messages).body
    assert current_step == second

    %{disposition: disposition, messages_history: messages, current_step: current_step} = process_respondent_response(respondent_id, "Yes")
    assert "started" == disposition
    assert  "Which is the second perfect number??" == List.last(messages).body
    assert current_step == third

    %{disposition: disposition, messages_history: messages, current_step: current_step} = process_respondent_response(respondent_id, "7")
    assert "started" == disposition
    assert  "What's the number of this question??" == List.last(messages).body
    assert current_step == fourth

    %{disposition: disposition, messages_history: messages, simulation_status: status, current_step: current_step} = process_respondent_response(respondent_id, "4")
    assert "completed" == disposition
    assert "Thank you for taking the survey" == List.last(messages).body
    assert current_step == nil
    assert Ask.Simulation.Status.ended == status
  end

  defp expected_submission(step, response), do: %{step_id: step["id"], response: response, step_name: submission_step_name(step)}
  defp expected_submission(step), do: %{step_id: step["id"], step_name: submission_step_name(step)}

  defp submission_step_name(step), do: step["store"] || step["title"]
end


defmodule SimulatorQuestionnaireSteps do
  import Ask.StepBuilder
  use Ask.DummySteps

  def one_section_dummy_steps, do: [section(id: "Section1", title: "First Section", randomize: false, steps: @dummy_steps)]

  def two_sections_dummy_steps do
    steps = @dummy_steps
    [section(id: "Section1", title: "First Section", randomize: false, steps: steps |> Enum.take(2)), section(id: "Section2", title: "Second Section", randomize: false, steps: steps |> Enum.drop(2))]
  end

  def four_sections_randomized_dummy_steps do
    [first, second, third, fourth] = @dummy_steps
    [
      section(id: "Section1", title: "First Section", randomize: true, steps: [first]),
      section(id: "Section2", title: "Second Section", randomize: true, steps: [second]),
      section(id: "Section3", title: "Third Section", randomize: true, steps: [third]),
      section(id: "Section4", title: "Fourth Section", randomize: true, steps: [fourth])
    ]
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

  def with_interim_partial_flag, do: [
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
  def only_ivr_steps, do: [
    multiple_choice_step(
      id: Ecto.UUID.generate,
      title: "Do you smoke?",
      prompt: prompt(
        ivr: tts_prompt("Do you smoke? Press 8 for YES, 9 for NO")
      ),
      store: "Smokes",
      choices: [
        choice(value: "Yes", responses: responses(ivr: ["8"])),
        choice(value: "No", responses: responses(ivr: ["9"]))
      ]
    ),
    multiple_choice_step(
      id: Ecto.UUID.generate,
      title: "Do you exercise",
      prompt: prompt(
        ivr: tts_prompt("Do you exercise? Press 1 for YES, 2 for NO")
      ),
      store: "Exercises",
      choices: [
        choice(value: "Yes", responses: responses(ivr: ["1"])),
        choice(value: "No", responses: responses(ivr: ["2"]))
      ]
    )
  ]

end
