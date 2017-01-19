defmodule Ask.RespondentGroupView do
  use Ask.Web, :view

  alias Ask.Respondent

  def render("index.json", %{respondent_groups: respondent_groups, project: project}) do
    %{data: (respondent_groups |> Enum.map(fn respondent_group ->
      render(Ask.RespondentGroupView, "respondent_group.json", respondent_group: respondent_group, project: project)
    end))}
  end

  def render("show.json", %{respondent_group: respondent_group, project: project}) do
    %{data: render(Ask.RespondentGroupView, "respondent_group.json", respondent_group: respondent_group, project: project)}
  end

  def render("respondent_group.json", %{respondent_group: respondent_group, project: project}) do
    sample = respondent_group.sample
    |> Enum.map(&Respondent.hash_phone_number(&1, project.salt))

    channels = respondent_group.channels
    |> Enum.map(&(&1.id))

    %{
      id: respondent_group.id,
      name: respondent_group.name,
      sample: sample,
      respondents_count: respondent_group.respondents_count,
      channels: channels,
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
