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

    Repo.transaction(fn ->
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
    end)
    |> case do
      {:ok, respondent_group} ->
        respondent_group
      err -> err
      end
  end

  def add_respondents(respondent_group, loaded_entries, file_name, conn) do
    respondent_group = Repo.preload(respondent_group, survey: :project)
    survey = respondent_group.survey

    phone_numbers =
      map_phone_numbers_from_loaded_entries(loaded_entries)
      |> remove_duplicates_with_respect_to(respondent_group)

    loaded_entries = clean_entries(loaded_entries, phone_numbers)

    Repo.transaction(fn ->
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
    end)
    |> case do
      {:ok, respondent_group} ->
        respondent_group
      err -> err
    end
  end

  def replace_respondents(respondent_group, loaded_entries) do
    respondent_group = Repo.preload(respondent_group, :survey)
    phone_numbers = map_phone_numbers_from_loaded_entries(loaded_entries)

    Repo.transaction(fn ->
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
    end)
    |> case do
      {:ok, respondent_group} ->
        respondent_group
      err -> err
    end
  end

  defp clean_entries(loaded_entries, phone_numbers) do
    Enum.filter(loaded_entries, fn %{phone_number: phone_number} ->
      phone_number in phone_numbers
    end)
  end

  defp remove_duplicates_with_respect_to(phone_numbers, group) do
    # Select numbers that already exist in the DB
    canonical_numbers = Enum.map(phone_numbers, &Respondent.canonicalize_phone_number/1)

    # Request in batches to avoid 'Prepared statement contains too many placeholders' errors
    process_batch = fn numbers ->
      Repo.all(
        from(r in Respondent,
          where: r.respondent_group_id == ^group.id and r.canonical_phone_number in ^numbers,
          select: r.canonical_phone_number
        )
      )
    end

    existing_numbers =
      canonical_numbers
      |> Enum.chunk_every(64_000)
      |> Enum.flat_map(process_batch)

    if Enum.empty?(existing_numbers) do
      # no duplicates
      phone_numbers
    else
      # And then remove them from phone_numbers (because they are duplicates)

      # the following is basically doing this, but optimized (to handle large
      # lists of respondents):
      # Enum.reject(phone_numbers, fn num ->
      #   Respondent.canonicalize_phone_number(num) in existing_numbers
      # end)

      # zip into map %{ canonical_number => phone_number }
      zip =
        canonical_numbers
        |> Enum.zip(phone_numbers)
        |> List.foldl(%{}, fn ({k, v}, zip) -> Map.put(zip, k, v) end)

      existing_numbers
      |> List.foldl(zip, fn (n, zip) -> Map.delete(zip, n) end) # remove duplicates (using canonical number)
      |> Map.values() # return the de-duplicated list of phone numbers
    end
  end

  def take_sample(loaded_entries) do
    Enum.take(loaded_entries, @sample_size)
    |> entries_for_sample()
  end

  def map_phone_numbers_from_loaded_entries(loaded_entries) do
    Enum.map(loaded_entries, fn %{phone_number: phone_number} -> phone_number end)
  end

  def loaded_phone_numbers(phone_numbers) do
    Enum.map(phone_numbers, fn phone_number -> %{phone_number: phone_number} end)
  end

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

  defp insert_respondents(phone_numbers, respondent_group) do
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
        disposition: :registered,
        stats: %Stats{},
        user_stopped: false,
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
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

  def load_entries(entries, survey) do
    case validate_entries(entries) do
      :ok ->
        loaded_entries = load_validated_entries(entries, survey)

        case validate_loaded_entries(loaded_entries, entries) do
          :ok ->
            {:ok, loaded_entries}

          {:error, invalid_entries} ->
            {:error, invalid_entries}
        end

      {:error, invalid_entries} ->
        {:error, invalid_entries}
    end
  end

  def disable_incentive_if_respondent_id!(entries, survey) do
    if survey.incentives_enabled and
         Enum.any?(entries, fn entry -> Respondent.is_respondent_id?(entry) end),
       do:
         Survey.changeset(survey, %{incentives_enabled: false})
         |> Repo.update!()
  end

  def disable_incentives_if_disabled_in_source!(survey, %{incentives_enabled: false}), do:
    Survey.changeset(survey, %{incentives_enabled: false})
    |> Repo.update!()
  def disable_incentives_if_disabled_in_source!(survey, _), do: survey

  defp validate_entries(entries) do
    if length(entries) == 0 do
      {:error, []}
    else
      invalid_entries =
        entries
        |> Stream.with_index()
        |> Stream.filter(fn {entry, _} -> !Respondent.is_phone_number?(entry) end)
        |> Stream.filter(fn {entry, _} -> !Respondent.is_respondent_id?(entry) end)
        |> Stream.map(fn {entry, index} ->
          %{entry: entry, line_number: index + 1, type: "invalid-phone-number"}
        end)
        |> Enum.to_list()

      case invalid_entries do
        [] ->
          :ok

        _ ->
          {:error, invalid_entries}
      end
    end
  end

  defp validate_loaded_entries(loaded_entries, entries) do
    loaded_respondent_ids =
      loaded_entries
      |> Enum.filter(fn loaded_entry -> Map.has_key?(loaded_entry, :hashed_number) end)
      |> Enum.map(fn %{hashed_number: hashed_number} -> hashed_number end)

    invalid_entries =
      entries
      |> Stream.with_index()
      |> Stream.filter(fn {entry, _} ->
        Respondent.is_respondent_id?(entry) and not (entry in loaded_respondent_ids)
      end)
      |> Stream.map(fn {entry, index} ->
        %{entry: entry, line_number: index + 1, type: "invalid-respondent-id"}
      end)
      |> Enum.to_list()

    case invalid_entries do
      [] ->
        :ok

      _ ->
        {:error, invalid_entries}
    end
  end

  defp load_validated_entries(entries, survey) do
    keep_digits = fn phone_number ->
      Regex.replace(~r/\D/, phone_number, "", [:global])
    end

    {phone_numbers, respondent_ids} = partition_entries(entries)

    phone_numbers
    |> Enum.map(fn phone_number -> %{phone_number: phone_number} end)
    |> Enum.concat(phone_numbers_from_respondent_ids(survey, respondent_ids))
    |> Enum.filter(&(!is_nil(&1)))
    |> Enum.uniq_by(fn %{phone_number: phone_number} -> keep_digits.(phone_number) end)
  end

  defp partition_entries(entries) do
    case Enum.group_by(entries, fn entry -> String.starts_with?(entry, "r") end) do
      %{false => phone_numbers, true => respondent_ids} -> {phone_numbers, respondent_ids}
      %{false => phone_numbers} -> {phone_numbers, []}
      %{true => respondent_ids} -> {[], respondent_ids}
    end
  end

  defp phone_numbers_from_respondent_ids(survey, respondent_ids) do
    respondents =
      Repo.all(
        from(s in Survey,
          join: r in Respondent,
          on: r.survey_id == s.id,
          where:
            s.project_id == ^survey.project_id and
              r.hashed_number in ^respondent_ids,
          select: [r.phone_number, r.hashed_number]
        )
      )

    Enum.map(respondents, fn [phone_number, hashed_number] ->
      %{
        phone_number: phone_number,
        hashed_number: hashed_number
      }
    end)
  end

  # For each existing group a new respondent group with the same name is created.
  # Each respondent group has a copy of every respondent (except refused and
  # ineligible) and channel association.
  def clone_respondents_groups_into(respondent_groups, survey) do
    groups_phone_numbers = phone_numbers_by_group_id(respondent_groups)

    Enum.map(respondent_groups, fn group ->
      loaded_phone_numbers =
        groups_phone_numbers
        |> Map.get(group.id)
        |> loaded_phone_numbers()

      new_group = create(group.name, loaded_phone_numbers, survey)
      copy_respondent_group_channels(group, new_group)

      new_group
    end)
  end

  defp phone_numbers_by_group_id(respondent_groups) do
    groups_ids = respondent_groups |> Enum.map(& &1.id)

    from(r in Respondent,
      where:
        r.respondent_group_id in ^groups_ids and
          r.disposition != :refused and
          r.disposition != :ineligible,
      select: [r.respondent_group_id, r.phone_number]
    )
    |> Repo.all()
    # group phone_numbers by respondent_group_id
    |> Enum.group_by(&List.first/1, &List.last/1)
  end

  defp copy_respondent_group_channels(respondent_group, new_respondent_group) do
    respondent_group =
      respondent_group
      |> Repo.preload(:respondent_group_channels)

    Repo.transaction(fn ->
      Enum.each(
        respondent_group.respondent_group_channels,
        fn respondent_group_channel ->
          RespondentGroupChannel.changeset(
            %RespondentGroupChannel{},
            %{
              respondent_group_id: new_respondent_group.id,
              channel_id: respondent_group_channel.channel_id,
              mode: respondent_group_channel.mode
            }
          )
          |> Repo.insert!()
        end
      )
    end)
  end
end
