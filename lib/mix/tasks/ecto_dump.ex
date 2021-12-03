defmodule Mix.Tasks.Ask.EctoDump do
  @moduledoc ""
  @shortdoc ""

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    if Mix.env() == :dev do
      Mix.Tasks.Ecto.Dump.run(args)
    end
  end
end
