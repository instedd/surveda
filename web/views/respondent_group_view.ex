defmodule Ask.RespondentGroupView do
  use Ask.Web, :view

  alias Ask.Respondent

  def render("index.json", %{respondent_groups: respondent_groups}) do
    %{data: render_many(respondent_groups, Ask.RespondentGroupView, "respondent_group.json")}
  end

  def render("show.json", %{respondent_group: respondent_group}) do
    %{data: render_one(respondent_group, Ask.RespondentGroupView, "respondent_group.json")}
  end

  def render("respondent_group.json", %{respondent_group: respondent_group}) do
    sample = respondent_group.sample |> Enum.map(&Respondent.mask_phone_number(&1))

    %{
      id: respondent_group.id,
      name: respondent_group.name,
      sample: sample,
      respondents_count: respondent_group.respondents_count,
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
