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

  # Convenience constructors
  defmacro simple(title_and_prompt) do
    quote do
      %{steps: [ %{prompts: [unquote(title_and_prompt)], title: unquote(title_and_prompt)} ]}
    end
  end

  defmacro simple(title, prompt) do
    quote do
      %{steps: [ %{prompts: [unquote(prompt)], title: unquote(title)} ]}
    end
  end

  defmacro simple(title, prompt, store) do
    quote do
      %{stores: unquote(store), steps: [ %{prompts: [unquote(prompt)], title: unquote(title)} ]}
    end
  end

  defmacro quota_completed(prompt) do
    quote do
      %{steps: [ %{prompts: [unquote(prompt)], title: "Quota completed"} ]}
    end
  end

  defmacro multiple(steps) do
    quote do
      %{steps: (Enum.map unquote(steps), fn(step) ->
        case step do
          {title, prompt} -> %{prompts: [prompt], title: title}
          title_and_prompt -> %{prompts: [title_and_prompt], title: title_and_prompt}
        end
      end)}
    end
  end

end
