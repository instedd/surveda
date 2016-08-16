defmodule Ask.StudyView do
  use Ask.Web, :view

  def render("index.json", %{studies: studies}) do
    %{data: render_many(studies, Ask.StudyView, "study.json")}
  end

  def render("show.json", %{study: study}) do
    %{data: render_one(study, Ask.StudyView, "study.json")}
  end

  def render("study.json", %{study: study}) do
    %{id: study.id,
      user_id: study.user_id,
      name: study.name}
  end
end
