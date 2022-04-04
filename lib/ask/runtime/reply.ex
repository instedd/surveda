defmodule Ask.Runtime.Reply do
  alias __MODULE__
  alias Ask.Runtime.ReplyStep

  defstruct stores: [],
            steps: [],
            disposition: nil,
            current_step: nil,
            total_steps: nil,
            error_message: nil

  def prompts(%Reply{steps: steps}) do
    Enum.flat_map(steps, fn step -> step.prompts end)
  end

  def disposition(%Reply{disposition: disposition}) do
    disposition
  end

  def steps(%Reply{steps: steps}) do
    steps
  end

  def steps(_) do
    []
  end

  def stores(%Reply{stores: stores}) do
    stores
  end

  def stores(_) do
    []
  end

  def num_digits(%Reply{steps: steps}) do
    List.last(steps)
    |> ReplyStep.num_digits()
  end

  def progress(reply) do
    if reply.current_step && reply.total_steps && reply.total_steps > 0 do
      100 * (reply.current_step / reply.total_steps)
    else
      # If no explicit progress is set in the reply, assume we are at the end.
      # This happens in the "thank you" and "quota completed" messages.
      100.0
    end
  end

  def first_step(reply) do
    reply |> steps() |> hd
  end
end

defmodule Ask.Runtime.ReplyStep do
  defstruct prompts: [],
            id: nil,
            title: nil,
            type: nil,
            choices: [],
            min: nil,
            max: nil,
            refusal: nil,
            num_digits: nil

  alias __MODULE__

  def new(
        prompts,
        title,
        type \\ "explanation",
        id \\ nil,
        choices \\ [],
        min \\ nil,
        max \\ nil,
        refusal \\ nil,
        num_digits \\ nil
      )

  def new([nil], _, _, _, _, _, _, _, _), do: nil
  def new([""], _, _, _, _, _, _, _, _), do: nil
  def new([%{"audio_source" => "tts", "text" => ""}], _, _, _, _, _, _, _, _), do: nil

  def new(prompts, title, type, id, choices, min, max, refusal, num_digits) do
    %ReplyStep{
      prompts: prompts,
      id: id,
      title: title,
      type: type,
      choices: choices,
      min: min,
      max: max,
      refusal: refusal,
      num_digits: num_digits
    }
  end

  def title_with_index(%ReplyStep{prompts: [_], title: title}, _), do: title
  def title_with_index(%ReplyStep{title: nil}, _), do: ""
  def title_with_index(%ReplyStep{title: ""}, _), do: ""
  def title_with_index(%ReplyStep{title: title}, index), do: "#{title} #{index}"

  def num_digits(%ReplyStep{num_digits: num_digits}), do: num_digits
  def num_digits(_), do: nil
end
