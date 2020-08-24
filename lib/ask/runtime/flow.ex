defmodule Ask.Runtime.Flow do
  # current_step: step_index | {section_index, step_index}
  defstruct current_step: nil, questionnaire: nil, mode: nil, language: nil, retries: 0, in_quota_completed_steps: false, has_sections: false, section_order: nil, ignored_values_from_relevant_steps: []
  alias Ask.{Repo, Questionnaire, Respondent}
  alias Ask.Runtime.{Reply, Step}
  alias Ask.Runtime.Flow.{Visitor, Message}
  alias __MODULE__

  @max_retries 2

  def start(quiz, mode) do
    has_sections = questionnaire_has_sections(quiz)

    section_order =
      if(has_sections) do
        randomize_sections(quiz)
      else
        nil
      end

    %Flow{
      questionnaire: quiz,
      mode: mode,
      language: quiz.default_language,
      has_sections: has_sections,
      section_order: section_order,
      ignored_values_from_relevant_steps: Questionnaire.ignored_values_from_relevant_steps(quiz)
    }
  end

  def step(flow, visitor, reply, old_disposition) do
    step(flow, visitor, reply, flow.mode, old_disposition)
  end

  def step(flow, visitor, reply, mode, old_disposition) do
    flow
    |> accept_reply(reply, visitor, mode)
    |> eval(mode, old_disposition)
  end

  def retry(flow, visitor, old_disposition) do
    {flow, %Reply{}, visitor}
    |> eval(flow.mode, old_disposition)
  end

  def dump(flow) do
    %{current_step: dump_current_step(flow.current_step), questionnaire_id: flow.questionnaire.id, mode: flow.mode, language: flow.language, retries: flow.retries, in_quota_completed_steps: flow.in_quota_completed_steps, section_order: flow.section_order}
  end

  def dump_current_step({first, second}) do
    [first, second]
  end

  def dump_current_step(number) do
    number
  end

  def load(state) do
    quiz = Repo.get(Questionnaire, state["questionnaire_id"])

    %Flow{
      questionnaire: quiz,
      current_step: load_current_step(state["current_step"]),
      mode: state["mode"],
      language: state["language"],
      retries: state["retries"],
      in_quota_completed_steps: state["in_quota_completed_steps"],
      has_sections: questionnaire_has_sections(quiz),
      section_order: state["section_order"],
      ignored_values_from_relevant_steps: Questionnaire.ignored_values_from_relevant_steps(quiz)
    }
  end

  def load_current_step([first, second]) do
    {first, second}
  end

  def load_current_step(number) do
    number
  end

  def questionnaire_has_sections(questionnaire) do
    Enum.any?(questionnaire.steps, fn(step) -> step["type"] == "section" end)
  end

  defp randomize_sections(questionnaire) do
    ids_to_randomize = Enum.with_index(questionnaire.steps)
      |> Enum.flat_map(fn {step, index} ->
        if step["type"] == "section" && step["randomize"] do
          [index]
        else
          []
        end
      end)

    {sections, _} = Enum.with_index(questionnaire.steps)
      |> Enum.flat_map_reduce(ids_to_randomize, fn({step, index}, acc) ->
        if step["type"] == "section" && step["randomize"] do
          extract_random_item(acc)
        else
          {[index], acc}
        end
      end)
    sections
  end

  defp extract_random_item(list) do
    item = Enum.random(list)
    {[item], List.delete(list, item)}
  end

  defp get_section_index(%{current_step: {index, _}}) do
    index
  end

  defp get_step_index(%{current_step: {_, index}}) do
    index
  end

  defp next_step_by_skip_logic(flow, step, reply_value, mode) do
    step
    |> Step.skip_logic(reply_value, mode, flow.language)
    |> next_step(flow)
  end

  def next_step(nil, %Flow{has_sections: true} = flow), do: advance_step_in_section(flow)
  def next_step(nil, flow), do: flow.current_step + 1
  def next_step("end", flow), do: flow |> end_flow
  def next_step("end_section", flow) do
    if flow.section_order do
      {next_section(get_section_index(flow), flow.section_order), 0}
    else
      {get_section_index(flow) + 1, 0}
    end
  end
  def next_step(next_id, %Flow{has_sections: true} = flow) do
    section_index = get_section_index(flow)
    {:ok, steps} =
      flow
      |> steps
      |> Enum.at(section_index)
      |> Map.fetch("steps")

    next_step_index = steps
      |> Enum.find_index(fn istep -> istep["id"] == next_id end)

    if (!next_step_index || get_step_index(flow) > next_step_index) do
      raise "Skip logic: invalid step id."
    else
      {section_index, next_step_index}
    end
  end
  def next_step(next_id, flow) do
    next_step_index =
      flow
      |> steps
      |> Enum.find_index(fn istep -> istep["id"] == next_id end)

    if (!next_step_index || flow.current_step > next_step_index) do
      raise "Skip logic: invalid step id."
    else
      next_step_index
    end
  end

  def advance_step_in_section(flow) do
    section_index = get_section_index(flow)
    step_index = get_step_index(flow)

    section = flow
      |> steps
      |> Enum.at(section_index)

    if section["type"] != "section" || length(section["steps"]) == step_index + 1 do
      if flow.section_order do
        {next_section(section_index, flow.section_order), 0}
      else
        {section_index + 1, 0}
      end
    else
      {section_index, step_index + 1}
    end
  end

  defp next_section(current_section_index, section_order) do
    current_index = Enum.find_index(section_order, fn(x) -> x == current_section_index end)
    Enum.at(section_order, current_index + 1)
  end

  defp advance_current_step(flow, step, reply_value, mode) do
    next_step =
      cond do
        !reply_value && !(step["type"] == "explanation") ->
          flow.current_step + 1
        :else ->
          next_step_by_skip_logic(flow, step, reply_value, mode)
      end

    %{flow | current_step: next_step}
  end

  def end_flow(%Flow{has_sections: true} = flow) do
    {length(steps(flow)), 0}
  end

  def end_flow(flow) do
    length(steps(flow))
  end

  defp accept_reply(%Flow{current_step: nil, has_sections: true, section_order: nil} = flow, :answer, visitor, _mode) do
    flow = %{flow | current_step: {0,0}}
    {flow, %Reply{}, visitor}
  end

  defp accept_reply(%Flow{current_step: nil, has_sections: true} = flow, :answer, visitor, _mode) do
    flow = %{flow | current_step: {Enum.at(flow.section_order, 0),0}}
    {flow, %Reply{}, visitor}
  end

  defp accept_reply(%Flow{current_step: nil} = flow, :answer, visitor, _mode) do
    flow = %{flow | current_step: 0}
    {flow, %Reply{}, visitor}
  end

  defp accept_reply(flow = %Flow{current_step: nil}, reply, visitor, mode) do
    accept_reply(%Flow{flow | current_step: 0}, reply, visitor, mode)
  end

  defp accept_reply(flow, :answer, visitor, _mode) do
    {flow, %Reply{}, visitor}
  end

  defp accept_reply(flow, :no_reply, visitor, _mode) do
    if flow.retries >= @max_retries do
      {:no_retries_left, %{flow | retries: 0}}
    else
      {%{flow | retries: flow.retries + 1}, %Reply{}, visitor}
    end
  end

  defp accept_reply(flow, {:reply, reply}, visitor, mode) do
    if Message.is_stop_reply({:reply, reply}) do
      :stopped
    else
      accept_reply_non_stop(flow, reply, visitor, mode)
    end
  end

  defp accept_reply(flow, {:reply_with_step_id, reply, step_id}, visitor, mode) do
    step = current_step(flow)
    case step do
      %{"id" => ^step_id} ->
        accept_reply(flow, {:reply, reply}, visitor, mode)
      _ ->
        accept_reply(flow, :answer, visitor, mode)
    end
  end

  defp accept_reply_non_stop(flow, reply, visitor, mode) do
    step = current_step(flow)

    reply_value = Step.validate(step, reply, mode, flow.language)

    # Select language to use in next questions
    flow =
      if reply_value != :invalid_answer && step["type"] == "language-selection" do
        %Flow{flow | language: reply_value}
      else
        flow
      end

    case reply_value do
      :invalid_answer ->
        if flow.retries >= @max_retries do
          {:no_retries_left, %{flow | retries: 0}}
        else
          visitor = visitor |> Visitor.accept_message(flow.questionnaire.settings["error_message"], flow.language, "Error")
          {%{flow | retries: flow.retries + 1}, %Reply{}, visitor}
        end
      nil ->
        flow = flow |> advance_current_step(step, reply_value, mode)
        {%{flow | retries: 0}, %Reply{}, visitor}
      {:refusal, reply_value} ->
        advance_after_reply(flow, step, reply_value, visitor, mode, stores: %{step["store"] => "REFUSED"})
      reply_value ->
        advance_after_reply(flow, step, reply_value, visitor, mode, stores: %{step["store"] => reply_value})
    end
  end

  defp advance_after_reply(flow, step, reply_value, visitor, mode, stores: stores) do
    flow = flow |> advance_current_step(step, reply_value, mode)
    {%{flow | retries: 0}, %Reply{stores: stores}, visitor}
  end

  def should_update_disposition(old_disposition, new_disposition)
  # This transitions are forced through flag steps and should always be allowed
  def should_update_disposition("queued", "interim partial"), do: true
  def should_update_disposition("queued", "completed"), do: true
  def should_update_disposition("queued", "refused"), do: true
  def should_update_disposition("queued", "ineligible"), do: true
  def should_update_disposition("queued", "rejected"), do: true
  def should_update_disposition("contacted", "interim partial"), do: true
  def should_update_disposition("contacted", "completed"), do: true
  def should_update_disposition("contacted", "ineligible"), do: true
  def should_update_disposition("contacted", "refused"), do: true
  def should_update_disposition("contacted", "rejected"), do: true
  def should_update_disposition("started", "interim partial"), do: true
  def should_update_disposition("started", "refused"), do: true
  def should_update_disposition("started", "ineligible"), do: true

  def should_update_disposition("registered", "queued"), do: true
  def should_update_disposition("queued", "failed"), do: true
  def should_update_disposition("queued", "contacted"), do: true
  def should_update_disposition("queued", "started"), do: true
  def should_update_disposition("contacted", "unresponsive"), do: true
  def should_update_disposition("contacted", "started"), do: true
  def should_update_disposition("started", "rejected"), do: true
  def should_update_disposition("started", "breakoff"), do: true
  def should_update_disposition("started", "completed"), do: true
  def should_update_disposition("interim partial", "completed"), do: true
  def should_update_disposition(nil, _), do: true
  def should_update_disposition(_, _), do: false

  defp stopped_disposition_from(old_disposition) do
    case old_disposition do
      "started" -> "breakoff"
      "interim partial" -> "partial"
      _ -> "refused"
    end
  end

  def failed_disposition_from(old_disposition) do
    case old_disposition do
      "queued" -> "failed"
      "contacted" -> "unresponsive"
      "started" -> "breakoff"
      "interim partial" -> "partial"
      "completed" -> old_disposition
      "ineligible" -> old_disposition
      "rejected" -> old_disposition
      "refused" -> old_disposition
      _ -> "failed"
    end
  end

  def resulting_disposition(old, new) do
    if Flow.should_update_disposition(old, new) do
      new
    else
      old
    end
  end

  # :next_step, :end_survey, {:jump, step_id}, :wait_for_reply
  defp run_step(state, %{"type" => "flag", "disposition" => disposition}) do
    if should_update_disposition(state.disposition, disposition) do
      {:ok, %{state | disposition: disposition}}
    else
      {:ok, state}
    end
  end

  defp run_step(state, %{"type" => "explanation"}) do
    {:ok, state}
  end

  defp run_step(state, _step) do
    {:wait_for_reply, state}
  end

  defp eval(:stopped, _mode, old_disposition) do
    {:stopped, nil, %Reply{disposition: stopped_disposition_from(old_disposition)}}
  end

  defp eval({:no_retries_left, flow}, _mode, _old_disposition) do
    {:no_retries_left, flow, %Reply{}}
  end

  defp eval({flow, state, visitor}, mode, old_disposition) do
    step = current_step(flow)
    case step do
      nil ->
        msg = flow.questionnaire.settings["thank_you_message"]
        visitor = if msg do
          visitor |> Visitor.accept_message(msg, flow.language, "Thank you")
        else
          visitor
        end
        {:end, nil, %{state | steps: Visitor.close(visitor)}}
      step ->
        case state |> run_step(step) do
          {:ok, state} ->
            case visitor |> Visitor.accept_step(step, flow.language) do
              {:continue, visitor} ->
                flow = %{flow | current_step: next_step_by_skip_logic(flow, step, nil, mode)}
                eval({flow, state, visitor}, mode, old_disposition)
              {:stop, visitor} ->
                reply(state, visitor, flow)
            end

          {:wait_for_reply, state} ->
            {_, visitor} = visitor |> Visitor.accept_step(step, flow.language)
            reply(state, visitor, flow)
        end
    end
  end

  defp reply(state, visitor, flow) do
    reply = %{state | steps: Visitor.close(visitor)}
    |> add_progress(flow)
    |> add_error_message(flow)

    {:ok, flow, reply}
  end

  defp add_progress(reply, flow) do
    {current_step, total_steps} = compute_progress(flow)
    %{reply | current_step: current_step, total_steps: total_steps}
  end

  defp add_error_message(reply, flow) do
    language = flow.language
    mode = flow.mode
    case flow.questionnaire.settings["error_message"] do
      %{^language => %{^mode => error_message}} ->
        %{reply | error_message: error_message}
      _ ->
        reply
    end
  end

  defp compute_progress(flow) do
    current_step_id = current_step(flow)["id"]
    steps = get_filtered_steps(flow)

    current_step_index = steps
    |> Enum.find_index(fn step -> step["id"] == current_step_id end)

    # Add 1 to the current step, because if we have 3 steps and we
    # are in the first one (index 0), we'd like it to be: 1/3, so 33%
    current_step_index = if current_step_index do
      current_step_index + 1
    else
      1
    end

    total_steps = length(steps)

    # If there's a thank you message, assume there's one more step
    total_steps =
      if has_thank_you_message?(flow) do
        total_steps + 1
      else
        total_steps
      end

    {current_step_index, total_steps}
  end

  def get_filtered_steps(%Flow{has_sections: true} = flow) do
    steps = steps(flow)
    flow.section_order |> Enum.flat_map(fn (index) ->
      item = Enum.at(steps, index)
      case item["type"] do
        "section" ->
          item["steps"]
            |> Enum.reject(fn step -> step["type"] == "flag" end)
        "flag" -> []
        _ -> [item]
      end
    end)
  end

  def get_filtered_steps(flow) do
    flow
      |> steps
      |> Enum.reject(fn step -> step["type"] == "flag" end)
  end

  def current_step(%Flow{has_sections: true} = flow) do
    case get_section_index(flow) do
      nil -> nil
      section_index ->
        flow
          |> steps
          |> Enum.at(section_index)
          |> get_step_from_section(get_step_index(flow))
    end
  end

  def current_step(flow) do
    flow
    |> steps
    |> Enum.at(flow.current_step)
  end

  def get_step_from_section(%{"type" => "section"} = section, index) do
    section
      |> Map.get("steps")
      |> Enum.at(index)
  end

  def get_step_from_section(step, _) do
    step
  end

  defp has_thank_you_message?(flow) do
    language = flow.language
    mode = flow.mode
    case flow.questionnaire.settings do
      %{"thank_you_message" => %{^language => %{^mode => _message}}} ->
        true
      _ ->
        false
    end
  end

  defp steps(flow) do
    if flow.in_quota_completed_steps do
      flow.questionnaire.quota_completed_steps
    else
      flow.questionnaire.steps
    end
  end

  def interim_partial_by_relevant_steps?(%{questionnaire: questionnaire} = _flow) do
    partial_relevant_config = questionnaire.partial_relevant_config
    partial_relevant_config["enabled"] && is_number(partial_relevant_config["min_relevant_steps"])
  end

  def min_relevant_steps(%{questionnaire: questionnaire} = _flow) do
    questionnaire.partial_relevant_config["min_relevant_steps"]
  end

  def relevant_response?(
        %Flow{questionnaire: questionnaire, ignored_values_from_relevant_steps: ignored_values},
        response
      ),
      do: Respondent.relevant_response?(questionnaire, ignored_values, response)
end

defmodule Ask.Runtime.Flow.Message do
  def reply(response) do
    {:reply, response}
  end

  def no_reply do
    :no_reply
  end

  def answer do
    :answer
  end

  def is_stop_reply({:reply, reply}), do:
    String.downcase(reply) == "stop"

  def is_stop_reply(_), do: false

end

defprotocol Ask.Runtime.Flow.Visitor do
  # -> {:continue, visitor} | {:stop, visitor}
  def accept_step(visitor, step, lang)
  def accept_message(visitor, message, lang, title)
  def close(visitor)
end

defmodule Ask.Runtime.Flow.TextVisitor do
  alias __MODULE__
  alias Ask.Runtime.Step
  defstruct reply_steps: [], mode: nil

  def new(mode) do
    %TextVisitor{mode: mode}
  end

  defimpl Ask.Runtime.Flow.Visitor, for: Ask.Runtime.Flow.TextVisitor do
    def accept_step(visitor, step, lang) do
      reply_step = Step.fetch(:reply_step, step, visitor.mode, lang)
      {:continue, add_reply_step(visitor, reply_step)}
    end

    def accept_message(visitor, message, lang, title) do
      reply_step = Step.fetch(:reply_msg, message, visitor.mode, lang, title)
      add_reply_step(visitor, reply_step)
    end

    defp add_reply_step(visitor, nil) do
      visitor
    end

    defp add_reply_step(visitor, reply_step) do
      %{visitor | reply_steps: visitor.reply_steps ++ [reply_step]}
    end

    def close(%TextVisitor{reply_steps: reply_steps}) do
      reply_steps
    end
  end
end

defmodule Ask.Runtime.Flow.WebVisitor do
  alias __MODULE__
  alias Ask.Runtime.Step
  defstruct reply_steps: [], mode: nil

  def new(mode) do
    %WebVisitor{mode: mode}
  end

  defimpl Ask.Runtime.Flow.Visitor, for: Ask.Runtime.Flow.WebVisitor do
    def accept_step(visitor, step, lang) do
      reply_step = Step.fetch(:reply_step, step, visitor.mode, lang)
      {step_action(step), add_reply_step(visitor, reply_step)}
    end

    defp step_action(%{"type" => "flag"}), do: :continue
    defp step_action(_), do: :stop

    def accept_message(visitor, message, lang, title) do
      reply_step = Step.fetch(:reply_msg, message, visitor.mode, lang, title)
      add_reply_step(visitor, reply_step)
    end

    defp add_reply_step(visitor, nil) do
      visitor
    end

    defp add_reply_step(visitor, reply_step) do
      %{visitor | reply_steps: visitor.reply_steps ++ [reply_step]}
    end

    def close(%WebVisitor{reply_steps: reply_steps}) do
      reply_steps
    end
  end
end
