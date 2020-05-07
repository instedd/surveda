defmodule Ask.Runtime.QuestionnaireSimulatorStoreTest do
  use Ask.ModelCase
  use Ask.DummySteps
  use Ask.MockTime
  alias Ask.Runtime.QuestionnaireSimulatorStore
  alias Ask.QuestionnaireSimulation

  setup do
    QuestionnaireSimulatorStore.start_link()
    :ok
  end

  test "if simulation is added to the store, then it can be retrieved immediately" do
    respondent_id = Ecto.UUID.generate()
    simulation = %QuestionnaireSimulation{messages: [%{body: "hello", type: "ao"}]}
    QuestionnaireSimulatorStore.add_respondent_simulation(respondent_id, simulation)
    assert simulation == QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
  end

  @tag :time_mock
  test "if simulation is added to the store, then it can be retrieved before its ttl expires" do
    set_actual_time()
    respondent_id = Ecto.UUID.generate()
    simulation = %QuestionnaireSimulation{messages: [%{body: "hello", type: "ao"}]}
    QuestionnaireSimulatorStore.add_respondent_simulation(respondent_id, simulation)

    time_passes(minutes: 4, seconds: 59) # ttl is 5 minutes
    GenServer.call(QuestionnaireSimulatorStore, :clean) # force the cleanup

    assert simulation == QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
  end

  test "adding a new simulation under an existing key is allowed and should update the stored value" do
    respondent_id = Ecto.UUID.generate()
    simulation = %QuestionnaireSimulation{messages: [%{body: "hello", type: "ao"}]}
    QuestionnaireSimulatorStore.add_respondent_simulation(respondent_id, simulation)
    new_simulation = %QuestionnaireSimulation{messages: [%{body: "hello", type: "ao"}, %{body: "hi", type: "at"}]}
    QuestionnaireSimulatorStore.add_respondent_simulation(respondent_id, new_simulation)
    assert new_simulation == QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
  end

  @tag :time_mock
  test "if entry ttl expired, then the store should remove that entry" do
    set_actual_time()
    respondent_id = Ecto.UUID.generate()
    simulation = %QuestionnaireSimulation{messages: [%{body: "hello", type: "ao"}]}
    QuestionnaireSimulatorStore.add_respondent_simulation(respondent_id, simulation)

    time_passes(minutes: 5, seconds: 1) # more than 5 minutes (default value) have passed
    GenServer.call(QuestionnaireSimulatorStore, :clean) # force the cleanup

    assert nil == QuestionnaireSimulatorStore.get_respondent_simulation(respondent_id)
  end
end
