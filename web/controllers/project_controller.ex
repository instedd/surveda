defmodule Ask.ProjectController do
  use Ask.Web, :api_controller

  alias Ask.{Project, Survey, ProjectMembership, Invite, Logger}

  def index(conn, _params) do
    memberships = conn
    |> current_user
    |> assoc(:project_memberships)
    |> preload(:project)
    |> Repo.all

    projects = memberships
    |> Enum.map(&(&1.project))
    |> Enum.uniq

    levels_by_project = memberships
    |> Enum.group_by(&(&1.project_id))
    |> Enum.to_list
    |> Enum.map(fn {id, memberships} ->
      level =
        if Enum.any?(memberships, &(&1.level == "owner")) do
          "owner"
        else
          if Enum.any?(memberships, &(&1.level == "editor")) do
            "editor"
          else
            if Enum.any?(memberships, &(&1.level == "admin")) do
              "admin"
            else
              "reader"
            end
          end
        end
      {id, level}
    end)
    |> Enum.into(%{})

    running_surveys_by_project = Repo.all(from p in Project,
      join: s in Survey,
      select: {p.id, count(s.id)},
      where: s.project_id == p.id and s.state == "running",
      group_by: p.id) |> Enum.into(%{})

    render(conn, "index.json",
      projects: projects,
      running_surveys_by_project: running_surveys_by_project,
      levels_by_project: levels_by_project)
  end

  def create(conn, %{"project" => project_params}) do
    user_changeset = conn
    |> current_user
    |> change

    params = Map.merge(project_params, %{"salt" => Ecto.UUID.generate})

    membership_changeset = %ProjectMembership{}
    |> change
    |> put_assoc(:user, user_changeset)
    |> put_change(:level, "owner")

    changeset = Project.changeset(%Project{}, params)
    |> put_assoc(:project_memberships, [membership_changeset])

    case Repo.insert(changeset) do
      {:ok, project} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_path(conn, :show, project))
        |> render("show.json", project: project, read_only: false, owner: true, level: "owner")
      {:error, changeset} ->
        Logger.warn "Error when creating a new project: #{inspect changeset}"
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    # Here we don't use load_project to avoid an extra query,
    # because we need to get the membership to know whether
    # the project is read_only.
    project = Project
    |> Repo.get!(id)

    user = conn
    |> current_user

    membership = project
    |> assoc(:project_memberships)
    |> where([m], m.user_id == ^user.id)
    |> Repo.one

    if membership do
      read_only = membership.level == "reader"
      owner = membership.level == "owner"
      render(conn, "show.json", project: project, read_only: read_only, owner: owner, level: membership.level)
    else
      raise Ask.UnauthorizedError
    end
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = conn
    |> load_project_for_change(id)

    changeset = project
    |> Project.changeset(project_params)

    case Repo.update(changeset) do
      {:ok, project} ->
        user = conn
        |> current_user

        membership = project
        |> assoc(:project_memberships)
        |> where([m], m.user_id == ^user.id)
        |> Repo.one

        owner = membership.level == "owner"
        render(conn, "show.json", project: project, read_only: false, owner: owner, level: membership.level)
      {:error, changeset} ->
        Logger.warn "Error when updating project #{project.id}: #{inspect changeset}"
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def leave(conn, %{"project_id" => project_id}) do
    user = conn
    |> current_user

    membership = Project
    |> Repo.get!(project_id)
    |> assoc(:project_memberships)
    |> where([m], m.user_id == ^user.id)
    |> Repo.one

    membership
    |> Repo.delete!()

    send_resp(conn, :no_content, "")
  end

  def delete(conn, %{"id" => id}) do
    conn
    |> load_project_for_change(id)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!()

    send_resp(conn, :no_content, "")
  end

  def autocomplete_vars(conn, %{"project_id" => id, "text" => text}) do
    conn
    |> load_project(id)

    text = text |> String.downcase
    like_text = "#{text}%"

    vars = (from v in Ask.QuestionnaireVariable,
      where: v.project_id == ^id,
      where: like(v.name, ^like_text),
      select: v.name
      )
    |> Repo.all
    |> Enum.filter(&(&1 != text))

    conn |> json(vars)
  end

  def autocomplete_primary_language(conn, %{"project_id" => id, "mode" => mode, "scope" => scope, "language" => language, "text" => text}) do
    conn
    |> load_project(id)

    text = text |> String.downcase
    like_text = "%#{text}%"

    translations = (from t in Ask.Translation,
      where: t.project_id == ^id,
      where: t.mode == ^mode,
      where: t.scope == ^scope,
      where: t.source_lang == ^language,
      where: like(t.source_text, ^like_text))
    |> Repo.all

    grouped_translations = translations
    |> Enum.group_by(&(&1.source_text))
    |> Enum.to_list
    |> Enum.map(fn {source_text, translations} ->
      translations = translations
      |> Enum.group_by(&(&1.target_lang))
      |> Enum.to_list
      |> Enum.map(fn {target_lang, translations} ->
        %{language: target_lang, text: hd(translations).target_text}
      end)
      %{text: source_text, translations: translations}
    end)

    conn |> json(grouped_translations)
  end

  def autocomplete_other_language(conn, %{"project_id" => id, "mode" => mode, "scope" => scope, "primary_language" => primary_language, "other_language" => other_language, "source_text" => source_text, "target_text" => target_text}) do
    conn
    |> load_project(id)

    target_text = target_text |> String.downcase
    like_text = "#{target_text}%"

    translations = (from t in Ask.Translation,
      where: t.project_id == ^id,
      where: t.mode == ^mode,
      where: t.scope== ^scope,
      where: t.source_lang == ^primary_language,
      where: t.target_lang == ^other_language,
      where: t.source_text == ^source_text,
      where: like(t.target_text, ^like_text),
      select: t.target_text
      )
    |> Repo.all |> Enum.uniq

    conn |> json(translations)
  end

  def collaborators(conn, %{"project_id" => id}) do
    memberships = conn
    |> load_project(id)
    |> assoc(:project_memberships)
    |> Repo.all
    |> Repo.preload(:user)
    |> Enum.map( fn m -> %{email: m.user.email, level: m.level, invited: false, code: nil} end )

    invites = Repo.all(from i in Invite, where: i.project_id == ^id)
    |> Enum.map( fn x -> %{email: x.email, level: x.level, invited: true, code: x.code} end )

    render(conn, "collaborators.json", collaborators: memberships ++ invites)
  end
end
