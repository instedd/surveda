defmodule Ask.Runtime.RespondentGroupAction do
  import Ecto.Query

  alias Ask.{
    Survey,
    Repo,
    Respondent,
    Stats,
    RespondentGroup,
    RespondentGroupChannel,
    ActivityLog
  }

  alias Ecto.Changeset
  @sample_size 5

  def create(name, loaded_entries, survey) do
    phone_numbers = map_phone_numbers_from_loaded_entries(loaded_entries)

    sample = take_sample(loaded_entries)

    respondents_count = phone_numbers |> length

    respondent_group =
      %RespondentGroup{
        name: name,
        survey_id: survey.id,
        sample: sample,
        respondents_count: respondents_count
      }
      |> Repo.insert!()
      |> Repo.preload(:respondent_group_channels)

    insert_respondents(phone_numbers, respondent_group)

    survey
    |> Repo.preload([:questionnaires])
    |> Repo.preload([:quota_buckets])
    |> Repo.preload(respondent_groups: [respondent_group_channels: :channel])
    |> Changeset.change()
    |> Survey.update_state()
    |> Repo.update!()

    respondent_group
  end

  def add_respondents(respondent_group, loaded_entries, file_name, conn) do
    respondent_group = Repo.preload(respondent_group, survey: :project)
    survey = respondent_group.survey

    phone_numbers =
      map_phone_numbers_from_loaded_entries(loaded_entries)
      |> remove_duplicates_with_respect_to(respondent_group)

    loaded_entries = clean_entries(loaded_entries, phone_numbers)

    insert_respondents(phone_numbers, respondent_group)

    respondents_count = Enum.count(phone_numbers)

    if Survey.launched?(survey) and respondents_count > 0 do
      ActivityLog.add_respondents(survey.project, conn, survey, %{
        file_name: file_name,
        respondents_count: respondents_count
      })
      |> Repo.insert!()
    end

    new_count = respondent_group.respondents_count + length(phone_numbers)

    new_sample = merge_sample(respondent_group.sample, loaded_entries)

    respondent_group
    |> RespondentGroup.changeset(%{"respondents_count" => new_count, "sample" => new_sample})
    |> Repo.update!()
  end

  def replace_respondents(respondent_group, loaded_entries) do
    respondent_group = Repo.preload(respondent_group, :survey)
    phone_numbers = map_phone_numbers_from_loaded_entries(loaded_entries)

    # First delete existing respondents from that group
    Repo.delete_all(
      from(r in Respondent,
        where: r.respondent_group_id == ^respondent_group.id
      )
    )

    # Then create respondents from the CSV file
    insert_respondents(phone_numbers, respondent_group)

    sample = take_sample(loaded_entries)
    respondents_count = phone_numbers |> length

    respondent_group
    |> RespondentGroup.changeset(%{
      "sample" => sample,
      "respondents_count" => respondents_count
    })
    |> Repo.update!()
    |> Repo.preload(:respondent_group_channels)
  end

  defp clean_entries(loaded_entries, phone_numbers) do
    Enum.filter(loaded_entries, fn %{phone_number: phone_number} ->
      phone_number in phone_numbers
    end)
  end

  defp remove_duplicates_with_respect_to(phone_numbers, group) do
    # Select numbers that already exist in the DB
    canonical_numbers = Enum.map(phone_numbers, &Respondent.canonicalize_phone_number/1)

    existing_numbers =
      Repo.all(
        from(r in Respondent,
          where: r.respondent_group_id == ^group.id,
          where: r.canonical_phone_number in ^canonical_numbers,
          select: r.canonical_phone_number
        )
      )

    # And then remove them from phone_numbers (because they are duplicates)
    # (no easier way to do this, plus we expect `existing_numbers` to
    # be empty or near empty)
    Enum.reject(phone_numbers, fn num ->
      Respondent.canonicalize_phone_number(num) in existing_numbers
    end)
  end

  def take_sample(loaded_entries) do
    Enum.take(loaded_entries, @sample_size)
    |> entries_for_sample()
  end

  def map_phone_numbers_from_loaded_entries(loaded_entries) do
    Enum.map(loaded_entries, fn %{phone_number: phone_number} -> phone_number end)
  end

  def loaded_phone_numbers(phone_numbers),
    do: Enum.map(phone_numbers, fn phone_number -> %{phone_number: phone_number} end)

  def merge_sample(old_sample, loaded_entries) do
    new_sample = old_sample ++ entries_for_sample(loaded_entries)
    Enum.take(new_sample, @sample_size)
  end

  defp entries_for_sample(loaded_entries) do
    Enum.map(loaded_entries, fn %{phone_number: phone_number} = loaded_entry ->
      respondent_id = Map.get(loaded_entry, :hashed_number)
      if respondent_id, do: respondent_id, else: phone_number
    end)
  end

  def insert_respondents(phone_numbers, respondent_group) do
    respondent_group = Repo.preload(respondent_group, survey: :project)

    map_respondent = fn phone_number ->
      canonical_number = Respondent.canonicalize_phone_number(phone_number)

      %{
        phone_number: phone_number,
        sanitized_phone_number: canonical_number,
        canonical_phone_number: canonical_number,
        survey_id: respondent_group.survey_id,
        respondent_group_id: respondent_group.id,
        hashed_number:
          Respondent.hash_phone_number(phone_number, respondent_group.survey.project.salt),
        disposition: "registered",
        stats: %Stats{},
        user_stopped: false,
        inserted_at: Timex.now(),
        updated_at: Timex.now()
      }
    end

    insert_respondents = fn respondents ->
      Repo.insert_all(Respondent, respondents)
    end

    Stream.map(phone_numbers, map_respondent)
    # Insert all respondent in the sample in chunks of 1K
    |> Stream.chunk_every(1_000)
    |> Stream.each(insert_respondents)
    |> Stream.run()
  end

  def update_channels(respondent_group_id, mode_channels) do
    from(gch in RespondentGroupChannel, where: gch.respondent_group_id == ^respondent_group_id)
    |> Repo.delete_all()

    Repo.transaction(fn ->
      Enum.each(mode_channels, fn %{"id" => channel_id, "mode" => mode} ->
        RespondentGroupChannel.changeset(%RespondentGroupChannel{}, %{
          respondent_group_id: respondent_group_id,
          channel_id: channel_id,
          mode: mode
        })
        |> Repo.insert()
      end)
    end)
  end
end
