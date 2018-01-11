defmodule Ask.FloipViewTest do
  use Ask.ConnCase, async: true

  test "it renders with no packages" do
    rendered = Ask.FloipView.render("index.json", %{packages: [], self_link: "http://foobar"})
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
    rendered = Ask.FloipView.render("index.json", %{packages: ["foo"], self_link: "http://foobar"})
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
