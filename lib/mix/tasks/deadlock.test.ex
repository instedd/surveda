defmodule Mix.Tasks.Ask.Deadlock.Test do
  import Ecto.Query
  use Mix.Task

  alias Ask.{Repo, Respondent}


  @shortdoc """
  Edits multiple respondents at the same time to try to generate a deadlock by respondent_stats locks.
  """
 
  @impl Mix.Task
  def run([survey_id]) do
    run([survey_id, :contacted, :queued])
  end
  
  # Prerequisites
  # have a survey with respondents 
  # - state:active, disposition:disposition_a
  # - state:active, disposition:disposition_b
  #
  # Steps to achieve that:
  # - create new survey and load respondent sample (without launching)
  # - update n respondents to be active & disposition_a
  # - update m respondents to be active & disposition_b
  def run([survey_id, disposition_a, disposition_b]) do
    Mix.shell().info("Starting deadlock test..")
    Mix.shell().info("Max concurrency: #{System.schedulers_online()}")
    Mix.shell().info("Updating respondents from dispositions #{disposition_a} <-> #{disposition_b}")

    Mix.Task.run("app.start")

    disposition_a_respondents = Repo.all(from r in Respondent, 
            where: r.survey_id == ^survey_id,
            where: r.state == :active,
            where: r.disposition == ^disposition_a
    )

    disposition_b_respondents = Repo.all(from r in Respondent, 
            where: r.survey_id == ^survey_id,
            where: r.state == :active,
            where: r.disposition == ^disposition_b
    )
    
    tasks1 = respondents_to_update_tasks(disposition_a_respondents, disposition_b)
    
    tasks2 = respondents_to_update_tasks(disposition_b_respondents, disposition_a)

    Task.yield_many(tasks1 ++ tasks2, :infinity)

  end

  def respondents_to_update_tasks(respondents, new_disposition) do
    respondents
    |> Enum.map(fn r -> 
      Task.async(fn -> 
        Respondent.update(r, %{disposition: new_disposition}, true) 
      end)
    end)
  end
end
