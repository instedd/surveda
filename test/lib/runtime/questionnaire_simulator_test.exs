defmodule QuestionnaireSimulatorTest do
  use Ask.ModelCase
  use Ask.DummySteps
  import Ask.Factory
  alias Ask.Runtime.{QuestionnaireSimulator, QuestionnaireSimulatorStore, QuestionnaireMobileWebSimulator}
  alias Ask.{Questionnaire, Repo, Simulation}
  alias Ask.QuestionnaireRelevantSteps

  setup do
    project = insert(:project)
    QuestionnaireSimulatorStore.start_link()
    start_simulation = fn quiz, mode ->
      {:ok, simulation} = QuestionnaireSimulator.start_simulation(project, quiz, mode)
      simulation
    end
    {:ok, project: project, start_simulation: start_simulation}
  end

  def questionnaire_with_steps(steps, options \\ []) do
    nil_thank_you_message = Keyword.get(options, :nil_thank_you_message, false)
    quiz = insert(:questionnaire, steps: steps, quota_completed_steps: [])
    quiz = if nil_thank_you_message do
      settings = Map.get(quiz, :settings)
      settings = Map.put(settings, :thank_you_message, nil)
      Map.put(quiz, :settings, settings)
    else
      quiz
    end
    Questionnaire.changeset(quiz, %{modes: ["sms", "mobileweb"]})
    |> Repo.update!
  end

  def process_respondent_response(respondent_id, response, mode \\ "sms") do
    {:ok, simulation_step} = QuestionnaireSimulator.process_respondent_response(respondent_id, response, mode)
    simulation_step
  end

  defp get_last_simulation_response(respondent_id) do
    {:ok, simulation_response} = QuestionnaireMobileWebSimulator.get_last_simulation_response(respondent_id)
    simulation_response
  end

  # Last simulation response only applies to Mobile Web mode
  describe "Mobile Web - last_simulation_response field" do
    test "should keep the last simulation response", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)

      # The simulation is started (the user asked for a simulation from the questionnaire screen)
      %{respondent_id: respondent_id} = first_simulation_response = start_simulation.(quiz, "mobileweb")
      last_simulation_response = get_last_simulation_response(respondent_id)

      assert first_simulation_response == last_simulation_response

      # The mobile web screen is loaded and the user read the intro message and consented to take the survey
      # The first step is shown.
      second_simulation_response = mobileweb_user_consented(respondent_id)
      last_simulation_response = get_last_simulation_response(respondent_id)

      refute first_simulation_response == last_simulation_response
      assert second_simulation_response == last_simulation_response
    end

    test "non-present simulation should return a SimulationStep with status: expired" do
      respondent_id =  Ecto.UUID.generate()

      last_simulation_response = get_last_simulation_response(respondent_id)

      assert Ask.Simulation.Status.expired == Map.get(last_simulation_response, :simulation_status)
      assert respondent_id == Map.get(last_simulation_response, :respondent_id)
    end

    test "SMS simulation should response invalid_simulation", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz, "sms")

      response = QuestionnaireMobileWebSimulator.get_last_simulation_response(respondent_id)

      assert {:error, :invalid_simulation} == response
    end
  end

  describe "base cases" do
    test "simulation works", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)

      Enum.map(["sms", "mobileweb"], fn mode ->
        assert_dummy_steps(start_simulation, quiz, mode)
      end)
    end

    test "with partial flag", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.with_interim_partial_flag)

      Enum.map(["sms", "mobileweb"], fn mode ->
        simulation = start_contacted(start_simulation, quiz, mode)

        %{respondent_id: respondent_id, disposition: disposition, simulation_status: status} = simulation
        assert "contacted" == disposition
        on_sms_assert_last_message(simulation, "Do you smoke? Reply 1 for YES, 2 for NO", mode)
        assert Simulation.Status.active == status

        %{disposition: disposition} = simulation = process_respondent_response(respondent_id, "No", mode)
        assert "started" == disposition
        on_sms_assert_last_message(simulation, "Do you exercise? Reply 1 for YES, 2 for NO", mode)

        %{disposition: disposition} = simulation = process_respondent_response(respondent_id, "Yes", mode)
        assert "interim partial" == disposition
        on_sms_assert_last_message(simulation, "Is this the last question?", mode)

        %{disposition: disposition, simulation_status: status} = simulation = process_respondent_response(respondent_id, "Yes", mode)
        assert "completed" == disposition
        on_sms_assert_last_message(simulation, "Thanks for completing this survey", mode)
        assert Simulation.Status.ended == status
      end)
    end
  end

  # Message history only applies to SMS mode
  describe "SMS - simulation messages_history field" do
    test "should maintain all respondent responses even if aren't valid", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id, messages_history: messages} = start_simulation.(quiz, "sms")
      assert  "Do you smoke? Reply 1 for YES, 2 for NO" == List.last(messages).body
      %{messages_history: messages} = process_respondent_response(respondent_id, "perhaps", "sms")
      [_question, response, error_message, re_question] = messages
      assert response.body == "perhaps"
      assert error_message.body == "You have entered an invalid answer"
      assert re_question.body == "Do you smoke? Reply 1 for YES, 2 for NO"
    end

    test "should include all the questions and responses", %{start_simulation: start_simulation} do
      steps = @dummy_steps
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz, "sms")

      process_respondent_response(respondent_id, "1", "sms") # 1 is a yes response
      process_respondent_response(respondent_id, "Y", "sms") # Y is a yes response
      process_respondent_response(respondent_id, "7", "sms") # numeric response

      %{messages_history: messages_history} = process_respondent_response(respondent_id, "4", "sms") # numeric response

      expected_messages_history = [
        %{body: "Do you smoke? Reply 1 for YES, 2 for NO", type: "ao"},
        %{body: "1", type: "at"},
        %{body: "Do you exercise? Reply 1 for YES, 2 for NO", type: "ao"},
        %{body: "Y", type: "at"},
        %{body: "Which is the second perfect number??", type: "ao"},
        %{body: "7", type: "at"},
        %{body: "What's the number of this question??", type: "ao"},
        %{body: "4", type: "at"},
        %{body: "Thanks for completing this survey", type: "ao"}
      ]

      assert expected_messages_history == messages_history
    end

  end

  describe "simulation submissions field" do
    test "SMS should include the explanation steps", %{start_simulation: start_simulation} do
      steps = SimulatorQuestionnaireSteps.with_explanation_first_step
      quiz = questionnaire_with_steps(steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz, "sms")
      %{submissions: submissions} = process_respondent_response(respondent_id, "No", "sms")

      [first, second, third] = steps
      expected_submissions = [
        expected_submission(first),
        expected_submission(second, "No"),
        expected_submission(third)
      ]
      assert expected_submissions == submissions
    end

    # Ideally, mobile web explanation steps should be considered submitted after the user read it.
    # But because the explanation steps aren't stored as answers, they behave differently.
    # This behaviour isn't ideal, but fortunately the simulation works properly for the end user.
    # The front-end marks them properly as the current step or a submission.
    test "Mobile Web explanation steps behave differently", %{start_simulation: start_simulation} do
      steps = SimulatorQuestionnaireSteps.with_explanation_first_step
      quiz = questionnaire_with_steps(steps)
      [first, second, third] = steps

      # The simulation is started (the user asked for a simulation from the questionnaire screen)
      %{respondent_id: respondent_id, submissions: submissions} = start_simulation.(quiz, "mobileweb")

      expected_submissions = []
      assert expected_submissions == submissions

      # The mobile web screen is loaded and the user read the intro message and consented to take the survey
      # The first explanation step is shown.
      %{submissions: submissions} = mobileweb_user_consented(respondent_id)

      expected_submissions = [
        expected_submission(first)
      ]
      assert expected_submissions == submissions

      # The explanation step is read
      %{submissions: submissions} = process_respondent_response(respondent_id, "", "mobileweb")

      expected_submissions = [
        expected_submission(first)
      ]
      assert expected_submissions == submissions

      # The question is answered and the 2nd explanation step is shown
      %{submissions: submissions} = process_respondent_response(respondent_id, "no", "mobileweb")

      expected_submissions = [
        expected_submission(first),
        expected_submission(second, "No"),
        expected_submission(third)
      ]
      assert expected_submissions == submissions
    end

    test "should indicate as response the valid-parsed responses", %{start_simulation: start_simulation} do
      steps = @dummy_steps
      first = hd(steps)
      quiz = questionnaire_with_steps(steps)

      Enum.map(["sms", "mobileweb"], fn mode ->
        %{respondent_id: respondent_id} = start_simulation.(quiz, mode)
        response = case mode do
          "sms" ->
            "1" # 1 is a yes response
          "mobileweb" ->
            "yes"
        end
        %{submissions: submissions} = process_respondent_response(respondent_id, response, mode)
        assert [expected_submission(first, "Yes")] == submissions
      end)
    end

    test "should not include the non-valid responses (since the step is not completed)", %{start_simulation: start_simulation} do
      steps = @dummy_steps
      quiz = questionnaire_with_steps(steps)

      Enum.map(["sms", "mobileweb"], fn mode ->
        %{respondent_id: respondent_id} = start_simulation.(quiz, mode)
        %{submissions: submissions} = process_respondent_response(respondent_id, "perhaps", mode)
        assert [] == submissions
      end)
    end

    test "should include all the responses, having or not the quiz a thank-you-message", %{start_simulation: start_simulation} do
      steps = @dummy_steps
      [first, second, third, fourth] = steps
      expected_submissions = [
        expected_submission(first, "Yes"),
        expected_submission(second, "Yes"),
        expected_submission(third, "7"),
        expected_submission(fourth, "4")
      ]

      Enum.map([true, false], fn nil_thank_you_message ->
        quiz = questionnaire_with_steps(steps, nil_thank_you_message: nil_thank_you_message)
        Enum.map(["sms", "mobileweb"], fn mode ->
          responses = case mode do
            "sms" ->
              ["1", "Y", "7", "4"]
              "mobileweb" ->
                ["yes", "yes", "7", "4"]
              end
              [first, second, third, fourth] = responses

          %{respondent_id: respondent_id} = start_simulation.(quiz, mode)
          process_respondent_response(respondent_id, first, mode)
          process_respondent_response(respondent_id, second, mode)
          process_respondent_response(respondent_id, third, mode)
          %{submissions: submissions} = process_respondent_response(respondent_id, fourth, mode)

          assert expected_submissions == submissions
        end)
      end)
    end
  end

  test "process_respondent_response of non-present simulation should return a SimulationStep with status: expired" do
    respondent_id =  Ecto.UUID.generate()
    Enum.map(["sms", "mobileweb"], fn mode ->
      %{simulation_status: status, respondent_id: rid} = process_respondent_response(respondent_id, "No", mode)
      assert Ask.Simulation.Status.expired == status
      assert respondent_id == rid
    end)
  end

  test "the simulator supports questionnaires with section", %{start_simulation: start_simulation} do
    quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.one_section_dummy_steps)
    # The flow should be the same as without section
    Enum.map(["sms", "mobileweb"], fn mode ->
      assert_dummy_steps(start_simulation, quiz, mode)
    end)
  end

  test "the simulator supports questionnaires with multiple sections", %{start_simulation: start_simulation} do
    quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.two_sections_dummy_steps)
    # The flow should be the same as without sections since are not randomized
    Enum.map(["sms", "mobileweb"], fn mode ->
      assert_dummy_steps(start_simulation, quiz, mode)
    end)
  end

  describe "simulator responses invalid_simulation" do
    test "when start_simulation with ivr mode", %{project: project} do
      quiz = questionnaire_with_steps(@dummy_steps)
      assert {:error, :invalid_simulation} == QuestionnaireSimulator.start_simulation(project, quiz, "ivr")
    end

    test "when start_simulation with sms/mobileweb mode but questionnaire doesn't have it", %{project: project}  do
      quiz =
        questionnaire_with_steps(SimulatorQuestionnaireSteps.only_ivr_steps())
        |> Questionnaire.changeset(%{modes: ["ivr"]})
        |> Repo.update!
      Enum.map(["sms", "mobileweb"], fn mode ->
        assert {:error, :invalid_simulation} == QuestionnaireSimulator.start_simulation(project, quiz, mode)
      end)
    end
  end

  describe "SMS - stop messages ends the simulation" do
    test "if stop message on contacted disposition, then final disposition is 'refused'", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id, disposition: starting_disposition} = start_simulation.(quiz, "sms")
      assert "contacted" == starting_disposition

      %{simulation_status: status, disposition: disposition} = process_respondent_response(respondent_id, "Stop", "sms")

      assert Simulation.Status.ended == status
      assert "refused" == disposition
    end

    test "if stop message on started disposition, then final disposition is 'breakoff'", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      %{respondent_id: respondent_id} = start_simulation.(quiz, "sms")
      %{disposition: previous_disposition} = process_respondent_response(respondent_id, "No", "sms")

      assert "started" == previous_disposition

      %{simulation_status: status, disposition: disposition} = process_respondent_response(respondent_id, "Stop", "sms")

      assert Simulation.Status.ended == status
      assert "breakoff" == disposition
    end

    test "if stop message on interim-partial disposition, then final disposition is 'breakoff'", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.with_interim_partial_flag)
      %{respondent_id: respondent_id} = start_simulation.(quiz, "sms")
      process_respondent_response(respondent_id, "No", "sms")
      %{disposition: previous_disposition} = process_respondent_response(respondent_id, "Yes", "sms")

      assert "interim partial" == previous_disposition

      %{simulation_status: status, disposition: disposition} = process_respondent_response(respondent_id, "Stop", "sms")

      assert Simulation.Status.ended == status
      assert "partial" == disposition
    end
  end

  describe "questionnaire with relevant steps" do
    test "if respondent answers min_relevant_steps, disposition should be 'interim partial'", %{start_simulation: start_simulation} do
      steps = QuestionnaireRelevantSteps.all_relevant_steps()
      quiz = questionnaire_with_steps(steps) |> Questionnaire.changeset(%{partial_relevant_config: %{"enabled" => true, "min_relevant_steps" => 2, "ignored_values" => ""}}) |> Repo.update!

      Enum.map(["sms", "mobileweb"], fn mode ->
        simulation = start_contacted(start_simulation, quiz, mode)

        %{respondent_id: respondent_id, disposition: disposition} = simulation
        assert "contacted" == disposition

        %{disposition: disposition} = process_respondent_response(respondent_id, "No", mode)
        assert "started" == disposition

        %{disposition: disposition} = process_respondent_response(respondent_id, "Yes", mode)
        assert "interim partial" == disposition
      end)
    end

    test "once the respondent reaches 'interim partial', simulation should return such disposition until completes the survey", %{start_simulation: start_simulation} do
      steps = QuestionnaireRelevantSteps.all_relevant_steps()
      quiz = questionnaire_with_steps(steps) |> Questionnaire.changeset(%{partial_relevant_config: %{"enabled" => true, "min_relevant_steps" => 2, "ignored_values" => ""}}) |> Repo.update!

      Enum.map(["sms", "mobileweb"], fn mode ->
        simulation = start_contacted(start_simulation, quiz, mode)

        %{respondent_id: respondent_id, disposition: disposition} = simulation
        assert "contacted" == disposition

        %{disposition: disposition} = process_respondent_response(respondent_id, "No", mode)
        assert "started" == disposition

        %{disposition: disposition} = process_respondent_response(respondent_id, "Yes", mode)
        assert "interim partial" == disposition

        %{disposition: disposition} = process_respondent_response(respondent_id, "7", mode)
        assert "interim partial" == disposition

        %{disposition: disposition, simulation_status: status} = process_respondent_response(respondent_id, "4", mode)
        assert "completed" == disposition
        assert Simulation.Status.ended == status
      end)
    end

    test "if respondent answer min_relevant_steps, even of different sections, disposition should be 'interim partial'", %{start_simulation: start_simulation} do
      steps = QuestionnaireRelevantSteps.relevant_steps_in_multiple_sections()
      quiz = questionnaire_with_steps(steps) |> Questionnaire.changeset(%{partial_relevant_config: %{"enabled" => true, "min_relevant_steps" => 2, "ignored_values" => ""}}) |> Repo.update!

      Enum.map(["sms", "mobileweb"], fn mode ->
        simulation = start_contacted(start_simulation, quiz, mode)

        %{respondent_id: respondent_id, disposition: disposition} = simulation
        assert "contacted" == disposition

        %{disposition: disposition} = process_respondent_response(respondent_id, "No", mode) # First relevant
        assert "started" == disposition

        %{disposition: disposition} = process_respondent_response(respondent_id, "5", mode)
        assert "started" == disposition

        %{disposition: disposition} = process_respondent_response(respondent_id, "No", mode) # Second relevant, in different section
        assert "interim partial" == disposition
      end)
    end
  end

  describe "questionnaire field" do
    test "should be included in start_simulation", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      Enum.map(["sms", "mobileweb"], fn mode ->
        assert start_simulation.(quiz, mode) |> Map.get(:questionnaire)
      end)
    end

    test "should not be included in process_respondent_response", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      Enum.map(["sms", "mobileweb"], fn mode ->
        %{respondent_id: respondent_id} = start_simulation.(quiz, mode)
        refute process_respondent_response(respondent_id, "No", mode) |> Map.get(:questionnaire)
      end)
    end

    test "if quiz doesn't have sections, steps should be in the same order", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(@dummy_steps)
      Enum.map(["sms", "mobileweb"], fn mode ->
        %{questionnaire: quex} = start_simulation.(quiz, mode)
        assert quiz.steps == quex.steps
      end)
    end

    test "if quiz has sections but not randomized, steps should be in the same order", %{start_simulation: start_simulation} do
      quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.two_sections_dummy_steps)
      Enum.map(["sms", "mobileweb"], fn mode ->
        %{questionnaire: quex} = start_simulation.(quiz, mode)
        assert quiz.steps == quex.steps
      end)
    end

    test "if quiz has randomized sections, steps should be in the order it will be send to respondent", %{start_simulation: start_simulation} do
      Enum.map(["sms", "mobileweb"], fn mode ->
        quiz = questionnaire_with_steps(SimulatorQuestionnaireSteps.four_sections_randomized_dummy_steps)
        %{section_order: section_order, questionnaire: quex} = randomized_section_order(quiz, start_simulation, mode)

        assert quex.steps != quiz.steps
        assert length(quex.steps) == length(quiz.steps)
        quex.steps |> Enum.with_index |> Enum.each(fn {step, index} ->
          original_step_index = section_order |> Enum.at(index)
          assert step == (quiz.steps |> Enum.at(original_step_index))
        end)
      end)
    end
  end

  # Starts different simulations until one has a shuffled section order
  defp randomized_section_order(quiz, start_simulation, mode) do
    %{questionnaire: quex, respondent_id: respondent_id} = start_simulation.(quiz, mode)
    %{section_order: section_order} = Ask.Runtime.QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
    if section_order == Enum.sort(section_order) do
      # Sections where not shuffled
      randomized_section_order(quiz, start_simulation, mode)
    else
      %{section_order: section_order, questionnaire: quex}
    end
  end

  defp assert_dummy_steps(start_simulation, quiz, mode) do
    simulation = start_contacted(start_simulation, quiz, mode)

    %{respondent_id: respondent_id, disposition: disposition, simulation_status: status, current_step: current_step} = simulation
    [first, second, third, fourth] = quiz |> Questionnaire.all_steps|> Enum.map(fn step -> step["id"] end)
    assert "contacted" == disposition
    on_sms_assert_last_message(simulation, "Do you smoke? Reply 1 for YES, 2 for NO", mode)
    assert current_step == first
    assert Ask.Simulation.Status.active == status

    %{disposition: disposition, current_step: current_step} = simulation = process_respondent_response(respondent_id, "No", mode)
    assert "started" == disposition
    on_sms_assert_last_message(simulation, "Do you exercise? Reply 1 for YES, 2 for NO", mode)
    assert current_step == second

    %{disposition: disposition, current_step: current_step} = simulation = process_respondent_response(respondent_id, "Yes", mode)
    assert "started" == disposition
    on_sms_assert_last_message(simulation, "Which is the second perfect number??", mode)
    assert current_step == third

    %{disposition: disposition, current_step: current_step} = simulation = process_respondent_response(respondent_id, "7", mode)
    assert "started" == disposition
    on_sms_assert_last_message(simulation, "What's the number of this question??", mode)
    assert current_step == fourth

    %{disposition: disposition, simulation_status: status, current_step: current_step} = simulation = process_respondent_response(respondent_id, "4", mode)
    assert "completed" == disposition
    on_sms_assert_last_message(simulation, "Thanks for completing this survey", mode)
    assert current_step == nil
    assert Ask.Simulation.Status.ended == status
  end

  defp expected_submission(step, response), do: %{step_id: step["id"], response: response, step_name: submission_step_name(step)}
  defp expected_submission(step), do: %{step_id: step["id"], step_name: submission_step_name(step)}

  defp submission_step_name(step), do: step["store"] || step["title"]

  defp mobileweb_user_consented(respondent_id) do
    process_respondent_response(respondent_id, :answer, "mobileweb")
  end

  defp start_contacted(start_simulation, quiz, mode) do
    simulation = start_simulation.(quiz, mode)
    simulation = if mode == "mobileweb" do
      %{respondent_id: respondent_id} = simulation
      mobileweb_user_consented(respondent_id)
    else
      simulation
    end
    simulation
  end

  defp on_sms_assert_last_message(simulation, message, mode) do
    if mode == "sms" do
      messages = Map.get(simulation, :messages_history)
      assert message == List.last(messages).body
    end
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
        sms: sms_prompt("Please consider taking this survey"),
        mobileweb: "Please consider taking this survey"
      ),
      skip_logic: nil
    ),
    multiple_choice_step(
      id: Ecto.UUID.generate,
      title: "Do you smoke?",
      prompt: prompt(
        sms: sms_prompt("Do you smoke? Reply 1 for YES, 2 for NO"),
        mobileweb: "Do you smoke?"
      ),
      store: "Smokes",
      choices: [
        choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], mobileweb: ["yes"])),
        choice(value: "No", responses: responses(sms: ["No", "N", "2"], mobileweb: ["no"]))
      ]
    ),
    explanation_step(
        id: Ecto.UUID.generate,
        title: "Explanation",
        prompt: prompt(
          sms: sms_prompt("Your responses will be used responsibly"),
          mobileweb: "Your responses will be used responsibly"
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
        ivr: tts_prompt("Do you smoke? Press 8 for YES, 9 for NO"),
        mobileweb: "Do you smoke?"
      ),
      store: "Smokes",
      choices: [
        choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["8"], mobileweb: ["Yes"])),
        choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["9"], mobileweb: ["No"]))
      ]
    ),
    multiple_choice_step(
      id: "bbb",
      title: "Do you exercise?",
      prompt: prompt(
        sms: sms_prompt("Do you exercise? Reply 1 for YES, 2 for NO"),
        ivr: tts_prompt("Do you exercise? Reply 1 for YES, 2 for NO"),
        mobileweb: "Do you exercise?"
      ),
      store: "Exercises",
      choices: [
        choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"], mobileweb: ["Yes"])),
        choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"], mobileweb: ["No"]))
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
        ivr: tts_prompt("Is this the last question?"),
        mobileweb: "Is this the last question?"
      ),
      store: "Last",
      choices: [
        choice(value: "Yes", responses: responses(sms: ["Yes", "Y", "1"], ivr: ["1"], mobileweb: ["Yes"])),
        choice(value: "No", responses: responses(sms: ["No", "N", "2"], ivr: ["2"], mobileweb: ["No"]))
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
