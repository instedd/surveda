defmodule Mix.Tasks.Ask.Deadlock.Test do
  import Ecto.Query
  use Mix.Task

  alias Ask.{Repo, Respondent}


  @shortdoc """
  Edits multiple respondents at the same time to try to generate a deadlock by respondent_stats locks.
  """
 
  # Prerequisites
  # have a survey with respondents 
  # - state:active, disposition:queued
  # - state:active, disposition:contacted
  #
  # Steps to achieve that:
  # - create new survey and load respondent sample (without launching)
  # - update n respondents to be active & queued
  # - update m respondents to be active & contacted
  @impl Mix.Task
  def run([survey_id]) do
    Mix.shell().info("Starting deadlock test..")
    Mix.shell().info("Max concurrency: #{System.schedulers_online()}")

    Mix.Task.run("app.start")

    # respondents = Repo.all(from r in Respondent, 
    #         where: r.survey_id == ^survey_id,
    #         where: r.state == :pending,
    #         where: r.disposition == :registered,
    #         limit: 1000
    #         )
    
    # Task.async_stream(respondents, fn r -> 
    #     :timer.sleep(Enum.random(50..1_000))
    #     disposition = Enum.random(Ecto.Enum.values(Ask.Respondent, :disposition))
    #     state = Enum.random(Ecto.Enum.values(Ask.Respondent, :state))
    #     mode = Enum.random(["['sms']", "['ivr']"])
    #     Respondent.update(r, %{disposition: disposition, state: state, mode: mode, quota_bucket_id: 1}, true) 
    #   end, 
    #   timeout: :infinity)
    # |> Stream.run()

    contacted_respondents = Repo.all(from r in Respondent, 
            where: r.survey_id == ^survey_id,
            where: r.state == :active,
            where: r.disposition == :contacted
    )

    queued_respondents = Repo.all(from r in Respondent, 
            where: r.survey_id == ^survey_id,
            where: r.state == :active,
            where: r.disposition == :queued
    )
    
    tasks1 = contacted_respondents |> Enum.map(fn r -> 
      Task.async(fn -> 
        :timer.sleep(Enum.random(50..500))
        r |> Respondent.update(%{disposition: :queued}, true) 
      end)
    end)
    
    tasks2 = queued_respondents |> Enum.map(fn r -> 
      Task.async(fn -> 
        :timer.sleep(Enum.random(50..500))
        r |> Respondent.update(%{disposition: :contacted}, true) 
      end)
    end)

    Task.yield_many(tasks1 ++ tasks2, :infinity)

  end
end
