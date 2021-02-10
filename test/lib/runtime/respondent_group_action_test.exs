defmodule Ask.Runtime.RespondentGroupActionTest do
  use Ask.ModelCase
  alias Ask.Runtime.RespondentGroupAction

  setup do
    {:ok, survey: insert(:survey)}
  end

  describe "load_entries" do
    test "loads a phone_number", %{survey: survey} do
      [phone_number] = entries = ["1000000001"]

      {result, loaded_entries} = RespondentGroupAction.load_entries(entries, survey)

      assert result == :ok
      assert loaded_entries == [%{phone_number: phone_number}]
    end

    test "loads an existing respondent_id", %{survey: survey} do
      phone_number = "1000000001"

      respondent_id =
        (add_survey_respondents(survey, [phone_number])
         |> Enum.at(0)).hashed_number

      entries = [respondent_id]

      {result, loaded_entries} = RespondentGroupAction.load_entries(entries, survey)

      assert result == :ok
      assert loaded_entries == [%{phone_number: phone_number, hashed_number: respondent_id}]
    end

    test "loads a phone_number and an existing respondent_id together", %{survey: survey} do
      phone_number_1 = "1000000001"
      phone_number_2 = "1000000002"

      respondent_id =
        (add_survey_respondents(survey, [phone_number_1])
         |> Enum.at(0)).hashed_number

      entries = [respondent_id, phone_number_2]

      {result, loaded_entries} = RespondentGroupAction.load_entries(entries, survey)

      assert result == :ok

      assert loaded_entries == [
               %{phone_number: phone_number_1, hashed_number: respondent_id},
               %{phone_number: phone_number_2}
             ]
    end

    test "validates an invalid entry", %{survey: survey} do
      [entry] = entries = ["foo"]

      {result, invalid_entries} = RespondentGroupAction.load_entries(entries, survey)

      assert result == :error
      assert invalid_entries == [%{entry: entry, line_number: 1}]
    end

    test "validates a non-existent respondent_id", %{survey: survey} do
      [respondent_id] = entries = ["r000000000001"]

      {result, invalid_entries} = RespondentGroupAction.load_entries(entries, survey)

      assert result == :error
      assert invalid_entries == [%{entry: respondent_id, line_number: 1, type: "not-found"}]
    end
  end

  defp add_survey_respondents(survey, phone_numbers) do
    {:ok, loaded_entries} = RespondentGroupAction.load_entries(phone_numbers, survey)
    respondent_group = RespondentGroupAction.create("foo", loaded_entries, survey)

    respondent_group
    |> assoc(:respondents)
    |> Repo.all()
  end
end
