ExUnit.start(exclude: [:skip])

Ecto.Adapters.SQL.Sandbox.mode(Ask.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:bypass)
