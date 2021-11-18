defmodule Ask.RetryStatTest do
  use Ask.ModelCase

  alias Ask.{RetryStat}

  @valid_attrs %{attempt: 1, count: 2, survey_id: 3, mode: ["sms"], retry_time: "2019101612", ivr_active: false}
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
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", ivr_active: false, survey_id: survey.id}

    {:ok, _} = RetryStat.add(filter)

    assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "increases stat" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", ivr_active: false, survey_id: survey.id}

    {:ok, _} = RetryStat.add(filter)
    {:ok, _} = RetryStat.add(filter)

    assert 2 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "increases specific stat" do
    survey_1 = insert(:survey)
    survey_2 = insert(:survey)
    mode_1 = ["sms", "ivr"]
    mode_2 = ["ivr", "sms"]
    retry_time_1 = "2019101615"
    retry_time_2 = "2019101616"

    %{attempt: 1, mode: mode_1, retry_time: retry_time_1, ivr_active: false, survey_id: survey_1.id}
    |> increase_stat(1)

    %{attempt: 2, mode: mode_1, retry_time: retry_time_1, ivr_active: false, survey_id: survey_1.id}
    |> increase_stat(2)

    %{attempt: 3, mode: mode_1, retry_time: retry_time_1, ivr_active: false, survey_id: survey_1.id}
    |> increase_stat(3)

    %{attempt: 1, mode: mode_2, retry_time: retry_time_1, ivr_active: false, survey_id: survey_1.id}
    |> increase_stat(4)

    %{attempt: 1, mode: mode_2, retry_time: retry_time_2, ivr_active: false, survey_id: survey_1.id}
    |> increase_stat(5)

    %{attempt: 1, mode: mode_2, retry_time: retry_time_2, ivr_active: false, survey_id: survey_2.id}
    |> increase_stat(6)

    stats_survey_1 = RetryStat.stats(%{survey_id: survey_1.id})
    stats_survey_2 = RetryStat.stats(%{survey_id: survey_2.id})

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 1, retry_time: retry_time_1, ivr_active: false, mode: mode_1}) == 1

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 2, retry_time: retry_time_1, ivr_active: false, mode: mode_1}) == 2

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 3, retry_time: retry_time_1, ivr_active: false, mode: mode_1}) == 3

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 1, retry_time: retry_time_1, ivr_active: false, mode: mode_2}) == 4

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 1, retry_time: retry_time_2, ivr_active: false, mode: mode_2}) == 5

    assert stats_survey_2
           |> RetryStat.count(%{attempt: 1, retry_time: retry_time_2, ivr_active: false, mode: mode_2}) == 6
  end

  test "decreases stat" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", ivr_active: false, survey_id: survey.id}

    {:ok, _} = RetryStat.add(filter)
    {:ok, %{id: id}} = RetryStat.add(filter)
    {:ok} = RetryStat.subtract(id)

    assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "decreases specific stat" do
    survey_1 = insert(:survey)
    survey_2 = insert(:survey)
    mode_1 = ["sms", "ivr"]
    mode_2 = ["ivr", "sms"]
    retry_time_1 = "2019101615"
    retry_time_2 = "2019101616"

    filter1 = %{attempt: 1, mode: mode_1, retry_time: retry_time_1, ivr_active: false, survey_id: survey_1.id}
    filter2 = %{attempt: 2, mode: mode_1, retry_time: retry_time_1, ivr_active: false, survey_id: survey_1.id}
    filter3 = %{attempt: 3, mode: mode_1, retry_time: retry_time_1, ivr_active: false, survey_id: survey_1.id}
    filter4 = %{attempt: 1, mode: mode_2, retry_time: retry_time_1, ivr_active: false, survey_id: survey_1.id}
    filter5 = %{attempt: 1, mode: mode_2, retry_time: retry_time_2, ivr_active: false, survey_id: survey_1.id}
    filter6 = %{attempt: 1, mode: mode_2, retry_time: retry_time_2, ivr_active: false, survey_id: survey_2.id}

    {:ok, %{id: id}} = increase_stat(filter1, 2)
    {:ok} = RetryStat.subtract(id)
    {:ok, %{id: id}} = increase_stat(filter2, 3)
    {:ok} = RetryStat.subtract(id)
    {:ok, %{id: id}} = increase_stat(filter3, 4)
    {:ok} = RetryStat.subtract(id)
    {:ok, %{id: id}} = increase_stat(filter4, 5)
    {:ok} = RetryStat.subtract(id)
    {:ok, %{id: id}} = increase_stat(filter5, 6)
    {:ok} = RetryStat.subtract(id)
    {:ok, %{id: id}} = increase_stat(filter6, 7)
    {:ok} = RetryStat.subtract(id)

    stats_survey_1 = RetryStat.stats(%{survey_id: survey_1.id})
    stats_survey_2 = RetryStat.stats(%{survey_id: survey_2.id})

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 1, retry_time: retry_time_1, ivr_active: false, mode: mode_1}) == 1

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 2, retry_time: retry_time_1, ivr_active: false, mode: mode_1}) == 2

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 3, retry_time: retry_time_1, ivr_active: false, mode: mode_1}) == 3

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 1, retry_time: retry_time_1, ivr_active: false, mode: mode_2}) == 4

    assert stats_survey_1
           |> RetryStat.count(%{attempt: 1, retry_time: retry_time_2, ivr_active: false, mode: mode_2}) == 5

    assert stats_survey_2
           |> RetryStat.count(%{attempt: 1, retry_time: retry_time_2, ivr_active: false, mode: mode_2}) == 6
  end

  test "doesn't decrease unexistent stat" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", ivr_active: false, survey_id: survey.id}

    {:error} = RetryStat.subtract(999)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "doesn't decrease stat when zero" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", ivr_active: false, survey_id: survey.id}

    {:ok, %{id: id}} = RetryStat.add(filter)
    {:ok} = RetryStat.subtract(id)

    {:error} = RetryStat.subtract(id)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "errors adding when the survey doesn't exists" do
    {:error, changeset} = RetryStat.add(Map.delete(@valid_attrs, :count))
    assert changeset.errors == [survey_id: {"does not exist", [constraint: :foreign, constraint_name: "retry_stats_survey_id_fkey"]}]
  end

  test "errors adding when a required field is missing" do
    survey = insert(:survey)
    valid_attrs = Map.delete(@valid_attrs, :count) |> Map.put(:survey_id, survey.id)

    {:ok, _} = RetryStat.add(valid_attrs)
    {:error, _} = RetryStat.add(Map.delete(valid_attrs, :survey_id))
    {:error, _} = RetryStat.add(Map.delete(valid_attrs, :mode))
    {:error, _} = RetryStat.add(Map.delete(valid_attrs, :attempt))
    {:error, _} = RetryStat.add(Map.delete(valid_attrs, :retry_time))
    {:error, _} = RetryStat.add(Map.delete(valid_attrs, :ivr_active))
  end

  test "returns no stats when the survey doesn't exists" do
    %{survey_id: valid_survey_id} = @valid_attrs
    assert RetryStat.stats(%{survey_id: valid_survey_id}) == []
  end

  test "doesn't count when a required field is missing" do
    survey = insert(:survey)
    valid_attrs = Map.delete(@valid_attrs, :count) |> Map.put(:survey_id, survey.id)

    {:ok, _} = RetryStat.add(valid_attrs)

    stats = RetryStat.stats(%{survey_id: survey.id})
    valid_count_attrs = %{attempt: valid_attrs.attempt, mode: valid_attrs.mode, retry_time: valid_attrs.retry_time, ivr_active: valid_attrs.ivr_active}

    assert RetryStat.count(stats, valid_count_attrs) == 1
    assert RetryStat.count(stats, Map.delete(valid_count_attrs, :retry_time)) == 1
    assert RetryStat.count(stats, Map.delete(valid_count_attrs, :ivr_active)) == 1
    assert RetryStat.count(stats, Map.delete(valid_count_attrs, :mode)) == 0
    assert RetryStat.count(stats, Map.delete(valid_count_attrs, :attempt)) == 0
  end

  test "increases stat concurrently" do
    survey = insert(:survey)
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", ivr_active: false, survey_id: survey.id}

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
    filter = %{attempt: 1, mode: ["sms", "ivr"], retry_time: "2019101615", ivr_active: false, survey_id: survey.id}

    {:ok, %{id: id}} = increase_stat(filter, 200)

    task1 =
      Task.async(fn ->
        decrease_stat(id, 50)
      end)

    task2 =
      Task.async(fn ->
        decrease_stat(id, 50)
      end)

    Task.await(task1)
    Task.await(task2)

    assert 100 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter)
  end

  test "transitions" do
    survey = insert(:survey)
    filter_from = %{attempt: 1, mode: ["ivr"], retry_time: "2019122309", ivr_active: true, survey_id: survey.id}
    filter_to = %{attempt: 1, mode: ["ivr"], retry_time: "2019122309", ivr_active: false, survey_id: survey.id}

    {:ok, %{id: id}} = RetryStat.add(filter_from)

    assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter_from)

    {:ok, _} = RetryStat.transition(id, filter_to)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter_from)
    assert 1 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(filter_to)
  end

  test "transitions concurrently" do
    survey = insert(:survey)

    from_filter = %{
      attempt: 1,
      mode: ["sms", "ivr"],
      retry_time: "2019101615",
      ivr_active: false,
      survey_id: survey.id
    }

    to_filter = %{
      attempt: 2,
      mode: ["sms", "ivr"],
      retry_time: "2019101615",
      ivr_active: false,
      survey_id: survey.id
    }

    {:ok, %{id: id}} = increase_stat(from_filter, 100)

    task1 =
      Task.async(fn ->
        transition_stat(id, to_filter, 50)
      end)

    task2 =
      Task.async(fn ->
        transition_stat(id, to_filter, 50)
      end)

    Task.await(task1)
    Task.await(task2)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(from_filter)
    assert 100 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(to_filter)
  end

  test "doesn't transition stat when zero" do
    survey = insert(:survey)

    from_filter = %{
      attempt: 1,
      mode: ["sms", "ivr"],
      retry_time: "2019101615",
      ivr_active: false,
      survey_id: survey.id
    }

    to_filter = %{
      attempt: 2,
      mode: ["sms", "ivr"],
      retry_time: "2019101615",
      ivr_active: false,
      survey_id: survey.id
    }

    {:ok, %{id: id}} = RetryStat.add(from_filter)
    {:ok} = RetryStat.subtract(id)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(from_filter)

    {:error, _} = RetryStat.transition(id, to_filter)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(from_filter)
    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(to_filter)
  end

  test "doesn't transition unexistent stat" do
    survey = insert(:survey)

    to_filter = %{
      attempt: 2,
      mode: ["sms", "ivr"],
      retry_time: "2019101615",
      ivr_active: false,
      survey_id: survey.id
    }

    {:error, _} = RetryStat.transition(999, to_filter)

    assert 0 == %{survey_id: survey.id} |> RetryStat.stats() |> RetryStat.count(to_filter)
  end

  defp increase_stat(filter, n) when n <= 1 do
    RetryStat.add(filter)
  end

  defp increase_stat(filter, n) do
    {:ok, _} = RetryStat.add(filter)
    increase_stat(filter, n - 1)
  end

  defp decrease_stat(id, n) when n <= 1 do
    {:ok} = RetryStat.subtract(id)
  end

  defp decrease_stat(id, n) do
    {:ok} = RetryStat.subtract(id)
    decrease_stat(id, n - 1)
  end

  defp transition_stat(id, increase_filter, n) when n <= 1 do
    {:ok, _} = RetryStat.transition(id, increase_filter)
  end

  defp transition_stat(id, increase_filter, n) do
    {:ok, _} = RetryStat.transition(id, increase_filter)
    transition_stat(id, increase_filter, n - 1)
  end
end
