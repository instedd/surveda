defmodule Ask.EctoDbSession do
  require Logger
  import Ecto.Query

  alias Ask.Session
  alias Ask.Repo

  def get_user_data(repo, user, creds, id_key) do 
    Ask.Session
    |> where([s], s.token == ^creds)
    |> Repo.one
    |> case do
      nil -> nil
      session -> 
        user_id = String.to_integer session.user_id

        session.user_type
        |> String.to_atom
        |> where([u], u.id == ^user_id)
        |> repo.one
    end
  end

  def put_credentials(_repo, user, creds, _id_key) do 
    id_str = "#{Map.get user, "id"}"
    params = %{
      token: creds, 
      user_type: Atom.to_string(user.__struct__), 
      user_id: Integer.to_string(user.id)
    }

    where(Session, [s], s.user_id == ^id_str)
    |> Repo.delete_all

    Session.changeset(Session.__struct__, params) 
    |> Repo.insert
    |> case do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete_credentials(_user, creds) do
    Session
    |> where([s], s.token == ^creds)
    |> Repo.one 
    |> case do
      nil -> 
        nil
      user -> 
        Repo.delete user
    end
  end
end