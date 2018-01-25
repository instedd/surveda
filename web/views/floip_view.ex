defmodule Ask.FloipView do
  use Ask.Web, :view

  alias Ask.FloipPackage

  def render("index.json", %{self_link: self_link, packages: packages}) do
    %{
      "links" => render_links(self_link),
      "data" => Enum.map(packages, &render_package/1)
    }
  end

  def render("show.json", %{self_link: self_link, responses_link: responses_link, survey: survey}) do
    %{
      "links" => render_links(self_link),
      "data" => %{
        "type" => "packages",
        "id" => survey.floip_package_id,
        "attributes" => %{
          "profile" => "flow-results-package",
          "flow-results-specification" => "1.0.0-rc1",
          "created" => DateTime.to_iso8601(FloipPackage.created_at(survey), :extended),
          "modified" => DateTime.to_iso8601(FloipPackage.modified_at(survey), :extended),
          "id" => survey.floip_package_id,
          "title" => survey.name,
          "resources" => [%{
            "api-data-url" => responses_link,
            "encoding" => "utf-8",
            "mediatype" => "application/json",
            "path" => nil,
            "schema" => %{
              "fields" => FloipPackage.fields,
              "questions" => FloipPackage.questions(survey)
            }
          }]
        }
      }
    }
  end

  def render("responses.json", %{
    self_link: self_link,
    descriptor_link: descriptor_link,
    survey: survey,
    responses: responses }) do

    %{
      "data" => %{
        "id" => survey.floip_package_id,
        "type" => "flow-results-data",
        "attributes" => %{
          "responses" => [],
        },
        "relationships" => %{
          "descriptor" => %{
            "links" => %{
              "self" => descriptor_link
            }
          },
          "links" => render_links(self_link, responses["next_link"], responses["previous_link"])
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
