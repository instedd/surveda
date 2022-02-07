Mox.defmock(GuissoMock, for: Guisso.Client)

defmodule Ask.MockGuissoCase do
  def enable_guisso() do
    Mox.expect(GuissoMock, :enabled?, fn -> true end)
    :ok
  end

  def disable_guisso() do
    Mox.expect(GuissoMock, :enabled?, fn -> false end)
    :ok
  end

  defmacro __using__(_) do
    quote do
      import Mox
      import Ask.MockGuissoCase

      setup :verify_on_exit!

      setup do
        # Methods that aren't mocked will delegate to the original client.
        Mox.stub_with(GuissoMock, Guisso)

        :ok
      end
    end
  end
end
