defmodule Ask.Repo.Migrations.RemoveRespondentStalledState do
  use Ecto.Migration
  import Ecto.Query
  import Ecto
  alias Ask.Repo

  defmodule Respondent do
    use Ask.Web, :model

    schema "respondents" do
      field :session, Ask.Ecto.Type.JSON
      field :state, :string, default: "pending"
      field :timeout_at, Timex.Ecto.DateTime
      field :disposition, :string, default: "registered"
    end

    def update_stalled_to_failed(respondent) do
      new_disposition = failed_disposition_from(respondent.disposition)

      respondent
      |> Respondent.changeset(%{state: "failed", session: nil, timeout_at: nil, disposition: new_disposition})
      |> Repo.update!
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:session, :state, :timeout_at, :disposition])
    end

    defp failed_disposition_from(old_disposition) do
      case old_disposition do
        "queued" -> "failed"
        "contacted" -> "unresponsive"
        "started" -> "breakoff"
        "interim partial" -> "partial"
        "completed" -> old_disposition
        "ineligible" -> old_disposition
        "rejected" -> old_disposition
        "refused" -> old_disposition
        _ -> "failed"
      end
    end

  end

  def up do
    Repo.all(from r in Respondent, where: r.state == "stalled")
    |> Enum.each(fn respondent -> Respondent.update_stalled_to_failed(respondent) end)
  end

  def down do
    # There is no way of reverting this
  end
end
