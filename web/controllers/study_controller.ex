defmodule Ask.StudyController do
  use Ask.Web, :controller

  alias Ask.Study

  def index(conn, _params) do
    studies = Repo.all(Study)
    render(conn, "index.json", studies: studies)
  end

  def create(conn, %{"study" => study_params}) do
    changeset = Study.changeset(%Study{user: Addict.Helper.current_user(conn)}, study_params)

    case Repo.insert(changeset) do
      {:ok, study} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", study_path(conn, :show, study))
        |> render("show.json", study: study)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    study = Repo.get!(Study, id)
    render(conn, "show.json", study: study)
  end

  def update(conn, %{"id" => id, "study" => study_params}) do
    study = Repo.get!(Study, id)
    changeset = Study.changeset(study, study_params)

    case Repo.update(changeset) do
      {:ok, study} ->
        render(conn, "show.json", study: study)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    study = Repo.get!(Study, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(study)

    send_resp(conn, :no_content, "")
  end
end
