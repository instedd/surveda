defmodule Ask.Runtime.ReplyHelper do
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

  defmacro ivr(title, prompt) do
    quote do
      %{
        steps: [%{
          prompts: [%{"audio_source" => "tts", "text" => unquote(prompt)}],
          title: unquote(title)
        }]
      }
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
