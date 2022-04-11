defmodule AskWeb.RespondentGroupView do
  use AskWeb, :view

  alias Ask.{Respondent, Repo}

  def render("index.json", %{respondent_groups: respondent_groups}) do
    %{
      data:
        respondent_groups
        |> Enum.map(fn respondent_group ->
          render(AskWeb.RespondentGroupView, "respondent_group.json",
            respondent_group: respondent_group
          )
        end)
    }
  end

  def render("show.json", %{respondent_group: respondent_group}) do
    %{
      data:
        render(AskWeb.RespondentGroupView, "respondent_group.json",
          respondent_group: respondent_group
        )
    }
  end

  def render("respondent_group.json", %{respondent_group: respondent_group}) do
    respondent_group = Repo.preload(respondent_group, :survey)
    sample = respondent_group.sample |> Enum.map(&Respondent.mask_respondent_entry/1)

    channels =
      respondent_group.respondent_group_channels
      |> Enum.map(fn group_channel ->
        %{id: group_channel.channel_id, mode: group_channel.mode}
      end)

    %{
      id: respondent_group.id,
      name: respondent_group.name,
      sample: sample,
      respondents_count: respondent_group.respondents_count,
      channels: channels,
      # TODO: presenting this survey flag in the respondent group is a workaround
      # In the future we should handle the survey / respondent_group UI updates better
      incentives_enabled: respondent_group.survey.incentives_enabled
    }
  end

  def render("empty.json", %{}) do
    %{data: %{}}
  end

  def render("invalid_entries.json", %{invalid_entries: entries, filename: filename}) do
    %{
      invalidEntries: entries,
      filename: filename
    }
  end
end
