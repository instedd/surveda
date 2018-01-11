defmodule Ask.FloipView do
  use Ask.Web, :view

  def render("index.json", %{self_link: self_link, packages: packages}) do
    %{
      "links" => %{
        "self" => self_link,
        "next" => nil,
        "previous" => nil
      },
      "data" => Enum.map(packages, &render_package/1)
    }
  end

  def render_package(package) do
    %{
      "type" => "packages",
      "id" => package
    }
  end
end
