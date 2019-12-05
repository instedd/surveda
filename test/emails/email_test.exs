defmodule Ask.EmailTest do
  use Ask.ModelCase
  use ExUnit.Case
  alias Ask.Email

  test "Reads SMTP_FROM_ADDRESS environment variable" do
    assert {"Test name", "test@email"} == Email.smtp_from_address()
  end

  test "Splits name and address when the format is valid" do
    assert {:ok, {"Other", "other@domain.com"}} ==
             Email.smtp_from_address("Other <other@domain.com>")
  end

  test "Errors and defaults to Instedd when the format is invalid" do
    assert {:error, {"InSTEDD Surveda", "noreply@instedd.org"}} ==
             Email.smtp_from_address("Invalid format")
  end
end
