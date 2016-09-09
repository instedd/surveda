defmodule Ask.RespondentController do
  use Ask.Web, :controller

  alias Ask.Respondent

  def index(conn, _params) do
    respondents = Repo.all(Respondent)
    render(conn, "index.json", respondents: respondents)
  end

  def create(conn, %{"file" => file, "survey_id" => survey_id}) do
    {integer_survey_id, _ } = Integer.parse survey_id
    {:ok, local_time } = Ecto.DateTime.cast :calendar.local_time()

    if Path.extname(file.filename) == ".csv" do
      entries = File.stream!(file.path) |>
      CSV.decode(separator: ?\t) |>
      Enum.map(fn row ->
        %{phone_number: Enum.at(row, 0), survey_id: integer_survey_id, inserted_at: local_time, updated_at: local_time}
      end)

      {inserted_rows, _} = Repo.insert_all(Respondent, entries)

      render(conn, "imported.json", inserted_rows: inserted_rows)
    else
      render(conn, "imported.json", inserted_rows: "error")
    end
  end

  def delete(conn, %{"id" => id}) do
    respondent = Repo.get!(Respondent, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(respondent)

    send_resp(conn, :no_content, "")
  end
end
