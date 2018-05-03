defmodule Ask.Repo do
  use Ecto.Repo, otp_app: :ask

  def reload(%module{id: id}) do
    get(module, id)
  end
end
