defmodule Ask.FoldersView do
  use Ask.Web, :view

  def render("show.json", %{ folder: folder }) do
    render_one(folder)
  end

  def render_one(folder) do
    %{
      id: folder.id,
      name: folder.name
    }
  end
end
