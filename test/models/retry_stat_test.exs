defmodule Ask.RetryStatTest do
  use Ask.ModelCase

  alias Ask.RetryStat

  @valid_attrs %{attempt: 1, count: 2, survey_id: 3, mode: ["sms"], retry_time: "2019101612"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = RetryStat.changeset(%RetryStat{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = RetryStat.changeset(%RetryStat{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "inserts stat" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", survey_id: survey.id}

    {:ok} = RetryStat.add!(filter)

    assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "increases stat" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", survey_id: survey.id}

    {:ok} = RetryStat.add!(filter)
    {:ok} = RetryStat.add!(filter)

    assert 2 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "increases specific stat" do
    survey_1 = insert(:survey)
    survey_2 = insert(:survey)
    mode_1 = ["sms", "ivr"]
    mode_2 = ["ivr", "sms"]
    retry_time_1 = "2019101615"
    retry_time_2 = "2019101616"

    %{attempt: 1, mode: mode_1, retry_time: retry_time_1, survey_id: survey_1.id}
      |> increase_stat(1)
    %{attempt: 2, mode: mode_1, retry_time: retry_time_1, survey_id: survey_1.id}
      |> increase_stat(2)
    %{attempt: 3, mode: mode_1, retry_time: retry_time_1, survey_id: survey_1.id}
      |> increase_stat(3)
    %{attempt: 1, mode: mode_2, retry_time: retry_time_1, survey_id: survey_1.id}
      |> increase_stat(4)
    %{attempt: 1, mode: mode_2, retry_time: retry_time_2, survey_id: survey_1.id}
      |> increase_stat(5)
    %{attempt: 1, mode: mode_2, retry_time: retry_time_2, survey_id: survey_2.id}
      |> increase_stat(6)

    stats_survey_1 = RetryStat.stats(%{survey_id: survey_1.id})
    stats_survey_2 = RetryStat.stats(%{survey_id: survey_2.id})

    assert stats_survey_1 |> RetryStat.count(%{attempt: 1, retry_time: retry_time_1, mode: mode_1}) == 1
    assert stats_survey_1 |> RetryStat.count(%{attempt: 2, retry_time: retry_time_1, mode: mode_1}) == 2
    assert stats_survey_1 |> RetryStat.count(%{attempt: 3, retry_time: retry_time_1, mode: mode_1}) == 3
    assert stats_survey_1 |> RetryStat.count(%{attempt: 1, retry_time: retry_time_1, mode: mode_2}) == 4
    assert stats_survey_1 |> RetryStat.count(%{attempt: 1, retry_time: retry_time_2, mode: mode_2}) == 5
    assert stats_survey_2 |> RetryStat.count(%{attempt: 1, retry_time: retry_time_2, mode: mode_2}) == 6
  end

  test "decreases stat" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", survey_id: survey.id}

    {:ok} = RetryStat.add!(filter)
    {:ok} = RetryStat.add!(filter)
    {:ok} = RetryStat.subtract!(filter)

    assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "decreases specific stat" do
    survey_1 = insert(:survey)
    survey_2 = insert(:survey)
    mode_1 = ["sms", "ivr"]
    mode_2 = ["ivr", "sms"]
    retry_time_1 = "2019101615"
    retry_time_2 = "2019101616"

    filter1 = %{attempt: 1, mode: mode_1, retry_time: retry_time_1, survey_id: survey_1.id}
    filter2 = %{attempt: 2, mode: mode_1, retry_time: retry_time_1, survey_id: survey_1.id}
    filter3 = %{attempt: 3, mode: mode_1, retry_time: retry_time_1, survey_id: survey_1.id}
    filter4 = %{attempt: 1, mode: mode_2, retry_time: retry_time_1, survey_id: survey_1.id}
    filter5 = %{attempt: 1, mode: mode_2, retry_time: retry_time_2, survey_id: survey_1.id}
    filter6 = %{attempt: 1, mode: mode_2, retry_time: retry_time_2, survey_id: survey_2.id}

    increase_stat(filter1, 2)
    {:ok} = RetryStat.subtract!(filter1)
    increase_stat(filter2, 3)
    {:ok} = RetryStat.subtract!(filter2)
    increase_stat(filter3, 4)
    {:ok} = RetryStat.subtract!(filter3)
    increase_stat(filter4, 5)
    {:ok} = RetryStat.subtract!(filter4)
    increase_stat(filter5, 6)
    {:ok} = RetryStat.subtract!(filter5)
    increase_stat(filter6, 7)
    {:ok} = RetryStat.subtract!(filter6)

    stats_survey_1 = RetryStat.stats(%{survey_id: survey_1.id})
    stats_survey_2 = RetryStat.stats(%{survey_id: survey_2.id})

    assert stats_survey_1 |> RetryStat.count(%{attempt: 1, retry_time: retry_time_1, mode: mode_1}) == 1
    assert stats_survey_1 |> RetryStat.count(%{attempt: 2, retry_time: retry_time_1, mode: mode_1}) == 2
    assert stats_survey_1 |> RetryStat.count(%{attempt: 3, retry_time: retry_time_1, mode: mode_1}) == 3
    assert stats_survey_1 |> RetryStat.count(%{attempt: 1, retry_time: retry_time_1, mode: mode_2}) == 4
    assert stats_survey_1 |> RetryStat.count(%{attempt: 1, retry_time: retry_time_2, mode: mode_2}) == 5
    assert stats_survey_2 |> RetryStat.count(%{attempt: 1, retry_time: retry_time_2, mode: mode_2}) == 6
  end

  test "doesn't decrease unexistent stat" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", survey_id: survey.id}

    {:error} = RetryStat.subtract!(filter)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "doesn't decrease stat when zero" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", survey_id: survey.id}

    {:ok} = RetryStat.add!(filter)
    {:ok} = RetryStat.subtract!(filter)

    {:error} = RetryStat.subtract!(filter)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "increases stat concurrently" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", survey_id: survey.id}

    task1 =
      Task.async(fn ->
        increase_stat(filter, 100)
      end)

    task2 =
      Task.async(fn ->
        increase_stat(filter, 100)
      end)

    Task.await(task1)
    Task.await(task2)

    assert 200 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "decreases stat concurrently" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", survey_id: survey.id}

    increase_stat(filter, 200)

    task1 =
      Task.async(fn ->
        decrease_stat(filter, 50)
      end)

    task2 =
      Task.async(fn ->
        decrease_stat(filter, 50)
      end)

    Task.await(task1)
    Task.await(task2)

    assert 100 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "transition" do
    survey = insert(:survey)
    filter_from = %{attempt: 1, mode: ["ivr"], retry_time: "", survey_id: survey.id}
    filter_to = %{attempt: 2, mode: ["ivr"], retry_time: "2019101615", survey_id: survey.id}

    {:ok} = RetryStat.add!(filter_from)

    assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter_from)

    {:ok} = RetryStat.transition!(filter_from, filter_to)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter_from)
    assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter_to)
  end

  defp increase_stat(filter, n) when n <= 1 do
    {:ok} = RetryStat.add!(filter)
  end

  defp increase_stat(filter, n) do
    {:ok} = RetryStat.add!(filter)
    increase_stat(filter, n - 1)
  end

  defp decrease_stat(filter, n) when n <= 1 do
    {:ok} = RetryStat.subtract!(filter)
  end

  defp decrease_stat(filter, n) do
    {:ok} = RetryStat.subtract!(filter)
    decrease_stat(filter, n - 1)
  end
end
