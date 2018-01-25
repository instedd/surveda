defmodule Ask.FloipViewTest do
  use Ask.ConnCase, async: true
  use Ask.DummySteps

  alias Ask.FloipView
  alias Ask.FloipPackage

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
      quiz1 = insert(:questionnaire, steps: @dummy_steps)

      survey = insert(:survey,
        floip_package_id: "foo",
        state: "running",
        name: "My First Survey",
        started_at: DateTime.utc_now(),
        questionnaires: [quiz1]
      )

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
            "title" => "My First Survey",
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

  describe "responses" do
    test "it renders" do
      quiz1 = insert(:questionnaire, steps: @dummy_steps)

      survey = insert(:survey,
        floip_package_id: "foo",
        state: "running",
        name: "My First Survey",
        started_at: DateTime.utc_now(),
        questionnaires: [quiz1]
      )

      responses = FloipPackage.responses(survey, "http://foobar/packages/responses")


      rendered = FloipView.render("responses.json", %{
        descriptor_link: "http://foobar/packages",
        self_link: "http://foobar/packages/responses",
        survey: survey,
        responses: responses
      })

      assert rendered == %{
        "data" => %{
          "type" => "flow-results-data",
          "id" => "foo",
          "attributes" => %{
            "responses" => []
          },
          "relationships" => %{
            "descriptor" => %{
              "links" => %{
                "self" => "http://foobar/packages"
              }
            },
            "links" => %{
              "self" => "http://foobar/packages/responses",
              "next" => "http://foobar/packages/responses?next",
              "previous" => "http://foobar/packages/responses?previous"
            }
          }
        }
      }
    end
  end
end
