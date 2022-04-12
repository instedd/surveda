defmodule Ask.Model do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      # Avoid microseconds. Mysql doesn't support them.
      # See [usec in datetime](https://hexdocs.pm/ecto_sql/Ecto.Adapters.MyXQL.html#module-usec-in-datetime)
      @timestamps_opts [type: :utc_datetime, usec: false]
    end
  end
end
