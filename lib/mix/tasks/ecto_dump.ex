defmodule Mix.Tasks.Ask.EctoDump do
  @moduledoc ""
  @shortdoc ""

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    if Mix.env() == :dev do
      Mix.Tasks.Ecto.Dump.run([])

      sql = File.read!("priv/repo/structure.sql")
      sql = String.replace(sql, ~r/ AUTO_INCREMENT=\d+ /, " ", [global: true])
      File.write!("priv/repo/structure.sql", sql)
    end
  end
end
