defmodule Ask.FloipViewTest do
  use Ask.ConnCase, async: true

  alias Ask.FloipView
  alias Ask.FloipPackage
  alias Ask.Survey

  describe "index" do
    test "it renders with no packages" do
      rendered = FloipView.render("index.json", %{packages: [], self_link: "http://foobar"})
      assert rendered == %{
        "links" => %{
          "self" => "http://foobar",
          "next" => nil,
          "previous" => nil
        },
        "data" => []
      }
    end

    test "it renders with one package" do
      rendered = FloipView.render("index.json", %{packages: ["foo"], self_link: "http://foobar"})
      assert rendered == %{
        "links" => %{
          "self" => "http://foobar",
          "next" => nil,
          "previous" => nil
        },
        "data" => [
          %{
            "type" => "packages",
            "id" => "foo"
          }
        ]
      }
    end
  end

  describe "show" do
    test "it renders" do
      survey = %Survey{
        floip_package_id: "foo",
        started_at: DateTime.utc_now()
      }

      rendered = FloipView.render("show.json", %{
        survey: survey,
        self_link: "http://foobar",
        responses_link: "http://foobar/responses"
      })

      assert rendered == %{
        "links" => %{
          "self" => "http://foobar",
          "next" => nil,
          "previous" => nil
        },
        "data" => %{
          "type" => "packages",
          "id" => "foo",
          "attributes" => %{
            "profile" => "flow-results-package",
            "flow-results-specification" => "1.0.0-rc1",
            "created" => DateTime.to_iso8601(FloipPackage.created_at(survey), :extended),
            "modified" => DateTime.to_iso8601(FloipPackage.modified_at(survey), :extended),
            "id" => "foo",
            "resources" => [%{
              "path" => nil,
              "api-data-url" => "http://foobar/responses",
              "mediatype" => "application/json",
              "encoding" => "utf-8",
              "schema" => %{
                "fields" => FloipPackage.fields,
                "questions" => FloipPackage.questions(survey)
              }
            }]
          }
        }
      }
    end
  end
end
