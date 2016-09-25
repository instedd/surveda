defmodule Ask.Base64Hasher do
  def hashpwsalt(password) do
    Base.encode64(password)
  end

  def checkpw(password, hash) do
    Base.decode64!(hash) == password
  end
end
