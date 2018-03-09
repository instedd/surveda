defmodule Ask.ProjectMembershipTest do
  use Ask.ModelCase

  alias Ask.ProjectMembership

  describe "authorize" do
    cases = [
      %{user_level: "reader", old_level: "reader", new_level: "reader"},
      %{user_level: "reader", old_level: "reader", new_level: "editor"},
      %{user_level: "reader", old_level: "reader", new_level: "admin"},
      %{user_level: "reader", old_level: "reader", new_level: "owner"},
      %{user_level: "reader", old_level: "editor", new_level: "reader"},
      %{user_level: "reader", old_level: "editor", new_level: "editor"},
      %{user_level: "reader", old_level: "editor", new_level: "admin"},
      %{user_level: "reader", old_level: "editor", new_level: "owner"},
      %{user_level: "reader", old_level: "admin", new_level: "reader"},
      %{user_level: "reader", old_level: "admin", new_level: "editor"},
      %{user_level: "reader", old_level: "admin", new_level: "admin"},
      %{user_level: "reader", old_level: "admin", new_level: "owner"},
      %{user_level: "reader", old_level: "owner", new_level: "reader"},
      %{user_level: "reader", old_level: "owner", new_level: "editor"},
      %{user_level: "reader", old_level: "owner", new_level: "admin"},
      %{user_level: "reader", old_level: "owner", new_level: "owner"},

      %{user_level: "editor", old_level: "reader", new_level: "reader", allowed: true},
      %{user_level: "editor", old_level: "reader", new_level: "editor", allowed: true},
      %{user_level: "editor", old_level: "reader", new_level: "admin"},
      %{user_level: "editor", old_level: "reader", new_level: "owner"},
      %{user_level: "editor", old_level: "editor", new_level: "reader", allowed: true},
      %{user_level: "editor", old_level: "editor", new_level: "editor", allowed: true},
      %{user_level: "editor", old_level: "editor", new_level: "admin"},
      %{user_level: "editor", old_level: "editor", new_level: "owner"},
      %{user_level: "editor", old_level: "admin", new_level: "reader"},
      %{user_level: "editor", old_level: "admin", new_level: "editor"},
      %{user_level: "editor", old_level: "admin", new_level: "admin"},
      %{user_level: "editor", old_level: "admin", new_level: "owner"},
      %{user_level: "editor", old_level: "owner", new_level: "reader"},
      %{user_level: "editor", old_level: "owner", new_level: "editor"},
      %{user_level: "editor", old_level: "owner", new_level: "admin"},
      %{user_level: "editor", old_level: "owner", new_level: "owner"},

      %{user_level: "admin", old_level: "reader", new_level: "reader", allowed: true},
      %{user_level: "admin", old_level: "reader", new_level: "editor", allowed: true},
      %{user_level: "admin", old_level: "reader", new_level: "admin", allowed: true},
      %{user_level: "admin", old_level: "reader", new_level: "owner"},
      %{user_level: "admin", old_level: "editor", new_level: "reader", allowed: true},
      %{user_level: "admin", old_level: "editor", new_level: "editor", allowed: true},
      %{user_level: "admin", old_level: "editor", new_level: "admin", allowed: true},
      %{user_level: "admin", old_level: "editor", new_level: "owner"},
      %{user_level: "admin", old_level: "admin", new_level: "reader", allowed: true},
      %{user_level: "admin", old_level: "admin", new_level: "editor", allowed: true},
      %{user_level: "admin", old_level: "admin", new_level: "admin", allowed: true},
      %{user_level: "admin", old_level: "admin", new_level: "owner"},
      %{user_level: "admin", old_level: "owner", new_level: "reader"},
      %{user_level: "admin", old_level: "owner", new_level: "editor"},
      %{user_level: "admin", old_level: "owner", new_level: "admin"},
      %{user_level: "admin", old_level: "owner", new_level: "owner"},

      %{user_level: "owner", old_level: "reader", new_level: "reader", allowed: true},
      %{user_level: "owner", old_level: "reader", new_level: "editor", allowed: true},
      %{user_level: "owner", old_level: "reader", new_level: "admin", allowed: true},
      %{user_level: "owner", old_level: "reader", new_level: "owner"},
      %{user_level: "owner", old_level: "editor", new_level: "reader", allowed: true},
      %{user_level: "owner", old_level: "editor", new_level: "editor", allowed: true},
      %{user_level: "owner", old_level: "editor", new_level: "admin", allowed: true},
      %{user_level: "owner", old_level: "editor", new_level: "owner"},
      %{user_level: "owner", old_level: "admin", new_level: "reader", allowed: true},
      %{user_level: "owner", old_level: "admin", new_level: "editor", allowed: true},
      %{user_level: "owner", old_level: "admin", new_level: "admin", allowed: true},
      %{user_level: "owner", old_level: "admin", new_level: "owner"},
      %{user_level: "owner", old_level: "owner", new_level: "reader"},
      %{user_level: "owner", old_level: "owner", new_level: "editor"},
      %{user_level: "owner", old_level: "owner", new_level: "admin"},
      %{user_level: "owner", old_level: "owner", new_level: "owner"},
    ]

    cases |> Enum.each(fn test_case ->

      @test_case test_case
      test "#{test_case.user_level} #{if test_case[:allowed], do: "can", else: "can't"} change from #{test_case.old_level} to #{test_case.new_level}" do
        changeset = ProjectMembership.changeset(%ProjectMembership{level: @test_case.old_level}, %{level: @test_case.new_level})

        if @test_case[:allowed] do
          assert ProjectMembership.authorize(changeset, @test_case.user_level) == changeset
        else
          assert_raise Ask.UnauthorizedError, fn ->
            ProjectMembership.authorize(changeset, @test_case.user_level)
          end
        end
      end
    end)
  end

end
