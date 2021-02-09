defmodule Ask.Runtime.RespondentGroup do
  import Ecto.Query
  alias Ask.{Survey, Repo, Respondent, Stats, RespondentGroup, RespondentGroupChannel}
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

  def take_sample(loaded_entries) do
    Enum.take(loaded_entries, @sample_size)
    |> entries_for_sample()
  end

  def map_phone_numbers_from_loaded_entries(loaded_entries) do
    Enum.map(loaded_entries, fn %{phone_number: phone_number} -> phone_number end)
  end

  def loaded_phone_numbers(phone_numbers),
    do:
      Enum.map(phone_numbers, fn phone_number -> %{phone_number: phone_number} end)

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
