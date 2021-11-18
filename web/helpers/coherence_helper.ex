# This file contains alternative implementations to wrap
# Coherence's. This is to overcome Coherence bugs (instead of forking).
defmodule Ask.Coherence.Helper do
  use Coherence.Config

  @doc """
  Checks if the confirmation token has expired.

  Returns true when the confirmation has expired.
  """
  @spec confirmable_expired?(Ecto.Schema.t) :: boolean
  def confirmable_expired?(user) do
    expired?(user.confirmation_sent_at, days: Config.confirmation_token_expire_days)
  end

  @doc """
  Test if a datetime has expired.

  Convert the datetime from DateTime format to Timex format to do
  the comparison given the time during in opts.

  ## Examples

      expired?(user.expire_at, days: 5)
      expired?(user.expire_at, minutes: 10)

      iex> DateTime.utc_now
      ...> |> Coherence.ControllerHelpers.expired?(days: 1)
      false

      iex> DateTime.utc_now
      ...> |> Coherence.ControllerHelpers.shift(days: -2)
      ...> |> DateTime.from_iso8601
      ...> |> elem(1)
      ...> |> Coherence.ControllerHelpers.expired?(days: 1)
      true
  """
  @spec expired?(nil | struct, Keyword.t) :: boolean
  def expired?(nil, _), do: true
  def expired?(datetime, opts) do
    not Timex.before?(DateTime.utc_now, shift(datetime, opts))
  end

  @doc """
  Shift a DateTime.

  ## Examples

      iex> DateTime.from_iso8601("2016-10-10T10:10:10Z")
      ...> |> elem(1)
      ...> |> Coherence.ControllerHelpers.shift(days: -2)
      ...> |> DateTime.from_iso8601
      ...> |> elem(1)
      ...> |> to_string
      "2016-10-08 10:10:10Z"
  """
  @spec shift(struct, Keyword.t) :: struct
  def shift(datetime, opts) do
    datetime
    |> Timex.to_erl
    |> Timex.to_datetime
    |> Timex.shift(opts)
  end
end
