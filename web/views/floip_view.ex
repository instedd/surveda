defmodule Ask.FloipView do
  use Ask.Web, :view

  def render("index.json", %{self_link: self_link, packages: packages}) do
    %{
      "links" => render_links(self_link),
      "data" => Enum.map(packages, &render_package/1)
    }
  end

  def render("show.json", %{
    created: created,
    modified: modified,
    self_link: self_link,
    responses_link: responses_link,
    id: id,
    title: title,
    fields: fields,
    questions: questions}) do
    %{
      "links" => render_links(self_link),
      "data" => %{
        "type" => "packages",
        "id" => id,
        "attributes" => %{
          "profile" => "flow-results-package",
          "flow-results-specification" => "1.0.0-rc1",
          "created" => created,
          "modified" => modified,
          "id" => id,
          "title" => title,
          "resources" => [%{
            "api-data-url" => responses_link,
            "encoding" => "utf-8",
            "mediatype" => "application/json",
            "path" => nil,
            "schema" => %{
              "fields" => fields,
              "questions" => questions
            }
          }]
        }
      }
    }
  end

  def render("responses.json", %{
    self_link: self_link,
    next_link: next_link,
    previous_link: previous_link,
    descriptor_link: descriptor_link,
    id: id,
    responses: responses }) do

    %{
      "data" => %{
        "id" => id,
        "type" => "flow-results-data",
        "attributes" => %{
          "responses" => responses,
        },
        "relationships" => %{
          "descriptor" => %{
            "links" => %{
              "self" => descriptor_link
            }
          },
          "links" => render_links(self_link, next_link, previous_link)
        }
      }
    }
  end

  def render_package(package) do
    %{
      "type" => "packages",
      "id" => package
    }
  end

  def render_links(self_link, next_link \\ nil, previous_link \\ nil) do
    %{
      "self" => self_link,
      "next" => next_link,
      "previous" => previous_link
    }
  end
end
