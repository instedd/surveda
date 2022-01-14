# lib/my_project/db_store.ex
defimpl Coherence.DbStore, for: Ask.User do
  alias Ask.Repo
  alias Ask.EctoDbSession

  def get_user_data(user, creds, id_key),
    do: EctoDbSession.get_user_data(Repo, user, creds, id_key)

  def put_credentials(user, creds, id_key),
    do: EctoDbSession.put_credentials(Repo, user, creds, id_key)

  def delete_credentials(user, creds),
    do: EctoDbSession.delete_credentials(user, creds)

  def delete_user_logins(user),
    do: EctoDbSession.delete_user_logins(user)
end
