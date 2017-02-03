defmodule Ask.Runtime.Reply do
  defstruct stores: [], prompts: [], disposition: nil

  def prompts(%{prompts: prompts}) do
    prompts
  end

  def disposition(%{disposition: disposition}) do
    disposition
  end
end
