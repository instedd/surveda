defmodule Ask.Runtime.RespondentGroupActionTest do
  use Ask.ModelCase
  alias Ask.Respondent
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

    test "loads an existent respondent_id", %{survey: survey} do
      other_survey = insert(:survey, project: survey.project)
      phone_number = "1000000001"

      respondent_id =
        create_respondent_group([phone_number], other_survey)
        |> first_respondent_id

      entries = [respondent_id]

      {result, loaded_entries} = RespondentGroupAction.load_entries(entries, survey)

      assert result == :ok
      assert loaded_entries == [%{phone_number: phone_number, hashed_number: respondent_id}]
    end

    test "loads a phone_number and an existent respondent_id together", %{survey: survey} do
      phone_number_1 = "1000000001"
      phone_number_2 = "1000000002"

      other_survey = insert(:survey, project: survey.project)

      respondent_id =
        create_respondent_group([phone_number_1], other_survey)
        |> first_respondent_id

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

    test "validates a non-existent respondent_id (but existent in another project)", %{
      survey: survey
    } do
      other_survey = insert(:survey)

      respondent_id =
        create_respondent_group(["1000000001"], other_survey)
        |> first_respondent_id

      entries = [respondent_id]

      {result, invalid_entries} = RespondentGroupAction.load_entries(entries, survey)

      assert result == :error
      assert invalid_entries == [%{entry: respondent_id, line_number: 1, type: "not-found"}]
    end
  end

  describe "create" do
    test "creates a new respondent from an existent respondent_id", %{survey: survey} do
      phone_number = "1000000001"
      other_survey = insert(:survey, project: survey.project)

      respondent_id =
        create_respondent_group([phone_number], other_survey)
        |> first_respondent_id

      {:ok, loaded_entries} = RespondentGroupAction.load_entries([respondent_id], survey)

      respondent_group = RespondentGroupAction.create("foo", loaded_entries, survey)

      assert respondent_group.sample == [respondent_id]

      assert Repo.get_by(Respondent,
               survey_id: survey.id,
               hashed_number: respondent_id,
               phone_number: phone_number
             )
    end
  end

  describe "add_respondents" do
    test "creates a new respondent from an existent respondent_id into a specific respondent group",
         %{survey: survey} do
      phone_number_1 = "1000000001"
      phone_number_2 = "1000000002"
      other_survey = insert(:survey, project: survey.project)

      respondent_group = create_respondent_group([phone_number_1], survey)

      respondent_id_1 = first_respondent_id(respondent_group)

      respondent_id_2 =
        create_respondent_group([phone_number_2], other_survey)
        |> first_respondent_id

      {:ok, loaded_entries} = RespondentGroupAction.load_entries([respondent_id_2], survey)

      respondent_group =
        RespondentGroupAction.add_respondents(respondent_group, loaded_entries, "bar", nil)

      assert respondent_group.sample == [phone_number_1, respondent_id_2]

      assert Repo.all(
               from(r in Respondent,
                 where: r.respondent_group_id == ^respondent_group.id,
                 select: [r.phone_number, r.hashed_number]
               )
             ) == [[phone_number_1, respondent_id_1], [phone_number_2, respondent_id_2]]
    end
  end

  describe "replace_respondents" do
    test "creates a new respondent from an existent respondent_id and replace the respondent group",
         %{survey: survey} do
      phone_number_1 = "1000000001"
      phone_number_2 = "1000000002"
      other_survey = insert(:survey, project: survey.project)

      respondent_group = create_respondent_group([phone_number_1], survey)

      respondent_id =
        create_respondent_group([phone_number_2], other_survey)
        |> first_respondent_id

      {:ok, loaded_entries} = RespondentGroupAction.load_entries([respondent_id], survey)

      respondent_group =
        RespondentGroupAction.replace_respondents(respondent_group, loaded_entries)

      assert respondent_group.sample == [respondent_id]

      assert Repo.all(
               from(r in Respondent,
                 where: r.respondent_group_id == ^respondent_group.id,
                 select: r.phone_number
               )
             ) == [phone_number_2]
    end
  end

  defp create_respondent_group(phone_numbers, survey) do
    {:ok, loaded_entries} = RespondentGroupAction.load_entries(phone_numbers, survey)
    RespondentGroupAction.create("foo", loaded_entries, survey)
  end

  defp first_respondent_id(respondent_group) do
    (respondent_group
     |> assoc(:respondents)
     |> Repo.all()
     |> Enum.at(0)).hashed_number
  end
end
