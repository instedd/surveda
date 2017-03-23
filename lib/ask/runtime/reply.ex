defmodule Ask.Runtime.Reply do
  defstruct stores: [], steps: [], disposition: nil

  def prompts(%{steps: steps}) do
    Enum.flat_map(steps, fn(step) -> step[:prompts] end)
  end

  def disposition(%{disposition: disposition}) do
    disposition
  end

  def disposition(_) do
    nil
  end

  def steps(%{steps: steps}) do
    steps
  end

  def stores(%{stores: stores}) do
    stores
  end

  def stores(_) do
    []
  end

  def step_title_with_index(step, index) do
    case length(step.prompts) do
      1 -> step[:title]
      _ -> case step[:title] do
             nil -> ""
             "" -> ""
             _ -> "#{step[:title]} #{index}"
           end
    end
  end
end
