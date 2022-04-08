defmodule Ask.Runtime.ReplyHelper do
  alias Ask.Runtime.ReplyStep
  alias Ask.Runtime.Reply

  defmacro simple(title_and_prompt) do
    quote do
      %Reply{
        steps: [
          %ReplyStep{prompts: [unquote(title_and_prompt)], title: unquote(title_and_prompt)}
        ]
      }
    end
  end

  defmacro simple(title, prompt) do
    quote do
      %Reply{steps: [%ReplyStep{prompts: [unquote(prompt)], title: unquote(title)}]}
    end
  end

  def simple_with_num_digits(title, prompt, num_digits) do
    %Reply{steps: [%ReplyStep{prompts: [prompt], title: title, num_digits: num_digits}]}
  end

  defmacro ivr(title, prompt) do
    quote do
      %Reply{
        steps: [
          %ReplyStep{
            prompts: [%{"audio_source" => "tts", "text" => unquote(prompt)}],
            title: unquote(title)
          }
        ]
      }
    end
  end

  defmacro simple(title, prompt, store) do
    quote do
      %Reply{
        stores: unquote(store),
        steps: [%ReplyStep{prompts: [unquote(prompt)], title: unquote(title)}]
      }
    end
  end

  defmacro quota_completed(prompt) do
    quote do
      %Reply{steps: [%ReplyStep{prompts: [unquote(prompt)], title: "Quota completed"}]}
    end
  end

  defmacro error(error_prompt, title, prompt) do
    quote do
      %Reply{
        steps: [
          %ReplyStep{prompts: [unquote(error_prompt)], title: "Error"},
          %ReplyStep{
            prompts: [unquote(prompt)],
            title: unquote(title)
          }
        ]
      }
    end
  end

  defmacro quota_completed_ivr(prompt) do
    quote do
      %Reply{steps: [%ReplyStep{prompts: [unquote(prompt)], title: "Quota completed"}]}
    end
  end

  defmacro error_ivr(error_prompt, title, prompt) do
    quote do
      %Reply{
        steps: [
          %ReplyStep{
            prompts: [%{"audio_source" => "tts", "text" => unquote(error_prompt)}],
            title: "Error"
          },
          %ReplyStep{
            prompts: [%{"audio_source" => "tts", "text" => unquote(prompt)}],
            title: unquote(title)
          }
        ]
      }
    end
  end

  defmacro multiple(steps) do
    quote do
      %Reply{
        steps:
          Enum.map(unquote(steps), fn step ->
            case step do
              {title, prompt} -> %ReplyStep{prompts: [prompt], title: title}
              title_and_prompt -> %ReplyStep{prompts: [title_and_prompt], title: title_and_prompt}
            end
          end)
      }
    end
  end
end
