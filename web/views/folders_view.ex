defmodule Ask.FoldersView do
  use Ask.Web, :view

  def render("index.json", %{ folders: folders }) do
    %{data: render_many(folders, Ask.FoldersView, "folder.json") }
  end

  def render("show.json", %{ folder: folder }) do
    %{data: render_one(folder, Ask.FoldersView, "folder.json") }
  end

  def render("folder.json", %{ folders: folder }) do
    %{id: folder.id,
      name: folder.name,
      project_id: folder.project_id
    }
  end
end
