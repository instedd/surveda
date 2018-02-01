defmodule Ask.FloipViewTest do
  use Ask.ConnCase, async: true
  alias Ask.FloipView

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
      rendered = FloipView.render("show.json", %{
        self_link: "http://foobar",
        responses_link: "http://foobar/responses",
        created: "some string date",
        modified: "some other string date",
        fields: ["field1", "field2"],
        questions: ["question1", "question2"],
        id: "foo",
        title: "My First Survey"
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
            "created" => "some string date",
            "modified" => "some other string date",
            "id" => "foo",
            "title" => "My First Survey",
            "resources" => [%{
              "path" => nil,
              "api-data-url" => "http://foobar/responses",
              "mediatype" => "application/json",
              "encoding" => "utf-8",
              "schema" => %{
                "fields" => ["field1", "field2"],
                "questions" => ["question1", "question2"]
              }
            }]
          }
        }
      }
    end
  end

  describe "responses" do
    test "it renders" do
      rendered = FloipView.render("responses.json", %{
        descriptor_link: "http://foobar/packages",
        self_link: "http://foobar/packages/responses",
        next_link: "http://foobar/packages/responses?next",
        previous_link: "http://foobar/packages/responses?previous",
        id: "foo",
        responses: [["response1_attribute1", "response1_attribute2"], ["response2_attribute1", "response2_attribute2"]]
      })

      assert rendered == %{
        "data" => %{
          "type" => "flow-results-data",
          "id" => "foo",
          "attributes" => %{
            "responses" => [["response1_attribute1", "response1_attribute2"], ["response2_attribute1", "response2_attribute2"]]
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
