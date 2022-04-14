defmodule Ask.RespondentsFilterTest do
  import Ecto.Query, only: [from: 2]
  use Ask.DataCase
  alias Ask.RespondentsFilter
  alias Ecto.Adapters.SQL

  @dummy_string "my-string"
  @white_space_dummy_string "foo bar baz"
  @dummy_date_string "2020-06-02"
  @dummy_date Timex.parse!(@dummy_date_string, RespondentsFilter.date_format_string())

  describe "parsing" do
    test "parse disposition from q" do
      q = "disposition:#{@dummy_string}"

      filter = RespondentsFilter.parse(q)

      assert filter.disposition == @dummy_string
    end

    test "parse white space disposition from q" do
      q = "disposition:\"#{@white_space_dummy_string}\""

      filter = RespondentsFilter.parse(q)

      assert filter.disposition == @white_space_dummy_string
    end

    test "parse since from q" do
      q = "since:#{@dummy_date}"

      filter = RespondentsFilter.parse(q)

      assert filter.since == @dummy_date
    end

    test "parse q" do
      q =
        "since:#{@dummy_date} disposition:disposition-#{@dummy_string} state:state-#{
          @dummy_string
        } mode:mode-#{@dummy_string}"

      filter = RespondentsFilter.parse(q)

      assert filter.since == @dummy_date
      assert filter.disposition == "disposition-#{@dummy_string}"
      assert filter.state == "state-#{@dummy_string}"
      assert filter.mode == "mode-#{@dummy_string}"

      # change the arguments order
      q =
        "disposition:disposition-#{@dummy_string} state:state-#{@dummy_string} since:#{
          @dummy_date
        }"

      filter = RespondentsFilter.parse(q)

      assert filter.since == @dummy_date
      assert filter.disposition == "disposition-#{@dummy_string}"
      assert filter.state == "state-#{@dummy_string}"
    end

    test "parse when irrelevant stuffs" do
      q = "foo disposition:#{@dummy_string} bar since:#{@dummy_date} baz"

      filter = RespondentsFilter.parse(q)

      assert filter.since == @dummy_date
      assert filter.disposition == @dummy_string

      # change the arguments order
      q = "disposition:#{@dummy_string} foo bar since:#{@dummy_date}"

      filter = RespondentsFilter.parse(q)

      assert filter.since == @dummy_date
      assert filter.disposition == @dummy_string
    end

    test "put disposition when empty" do
      filter = %RespondentsFilter{}

      filter = RespondentsFilter.put_disposition(filter, @dummy_string)

      assert filter.disposition == @dummy_string
      refute filter.since
    end

    test "put disposition when since" do
      filter = %RespondentsFilter{since: @dummy_date}

      filter = RespondentsFilter.put_disposition(filter, @dummy_string)

      assert filter.since == @dummy_date
      assert filter.disposition == @dummy_string
    end

    test "put disposition when exists" do
      filter = %RespondentsFilter{
        disposition: "old-disposition",
        since: @dummy_date
      }

      filter = RespondentsFilter.put_disposition(filter, @dummy_string)

      assert filter.since == @dummy_date
      assert filter.disposition == @dummy_string
    end

    test "parse since when empty" do
      filter = %RespondentsFilter{}

      filter = RespondentsFilter.parse_since(filter, @dummy_date_string)

      assert filter.since == @dummy_date
      refute filter.disposition
    end

    test "parse since when disposition" do
      filter = %RespondentsFilter{disposition: @dummy_string}

      filter = RespondentsFilter.parse_since(filter, @dummy_date_string)

      assert filter.since == @dummy_date
      assert filter.disposition == @dummy_string
    end

    test "parse since when exists" do
      filter = %RespondentsFilter{
        disposition: @dummy_string,
        since: @dummy_date
      }

      filter = RespondentsFilter.parse_since(filter, @dummy_date_string)

      assert filter.since == @dummy_date
      assert filter.disposition == @dummy_string
    end

    test "put state" do
      filter = %RespondentsFilter{}

      filter = RespondentsFilter.put_state(filter, @dummy_string)

      assert filter.state == @dummy_string
    end

    test "parse mode" do
      filter = %RespondentsFilter{}

      dummy_filter = RespondentsFilter.parse_mode(filter, @dummy_string)
      mobileweb_filter = RespondentsFilter.parse_mode(filter, "mobile web")

      assert dummy_filter.mode == @dummy_string
      assert mobileweb_filter.mode == "mobileweb"
    end
  end

  describe "filtering" do
    setup do
      now = Timex.now()
      insert_respondents_set(now)

      {
        :ok,
        now: now, total_respondents_count: count_all_respondents()
      }
    end

    test "filter by disposition", %{total_respondents_count: total_respondents_count} do
      queued_filter_where = filter_where(:disposition, "queued")
      started_filter_where = filter_where(:disposition, "started")
      contacted_filter_where = filter_where(:disposition, "contacted")

      queued_respondents_count = filter_respondents_and_count(queued_filter_where)
      started_respondents_count = filter_respondents_and_count(started_filter_where)
      contacted_respondents_count = filter_respondents_and_count(contacted_filter_where)

      assert total_respondents_count == 45
      assert queued_respondents_count == 6
      assert started_respondents_count == 15
      assert contacted_respondents_count == 24
    end

    test "filter by state", %{total_respondents_count: total_respondents_count} do
      pending_filter_where = filter_where(:state, "pending")
      active_filter_where = filter_where(:state, "active")
      cancelled_filter_where = filter_where(:state, "cancelled")

      pending_respondents_count = filter_respondents_and_count(pending_filter_where)
      active_respondents_count = filter_respondents_and_count(active_filter_where)
      cancelled_respondents_count = filter_respondents_and_count(cancelled_filter_where)

      assert total_respondents_count == 45
      assert pending_respondents_count == 6
      assert active_respondents_count == 15
      assert cancelled_respondents_count == 24
    end

    test "filter by mode", %{total_respondents_count: total_respondents_count} do
      sms_filter_where = filter_where(:mode, "sms")
      ivr_filter_where = filter_where(:mode, "ivr")
      mobile_web_filter_where = filter_where(:mode, "mobileweb")

      sms_respondents_count = filter_respondents_and_count(sms_filter_where)
      ivr_respondents_count = filter_respondents_and_count(ivr_filter_where)
      mobileweb_respondents_count = filter_respondents_and_count(mobile_web_filter_where)

      assert total_respondents_count == 45
      assert sms_respondents_count == 15
      assert ivr_respondents_count == 23
      assert mobileweb_respondents_count == 27
    end

    test "filter by since", %{
      now: now,
      total_respondents_count: total_respondents_count
    } do
      yesterday_filter_where = since_days_ago_filter_where(now, 1)
      three_days_ago_filter_where = since_days_ago_filter_where(now, 3)
      five_days_ago_filter_where = since_days_ago_filter_where(now, 5)

      since_yesterday_respondents_count = filter_respondents_and_count(yesterday_filter_where)

      since_three_days_ago_respondents_count =
        filter_respondents_and_count(three_days_ago_filter_where)

      since_five_days_ago_respondents_count =
        filter_respondents_and_count(five_days_ago_filter_where)

      assert total_respondents_count == 45
      assert since_yesterday_respondents_count == 12
      assert since_three_days_ago_respondents_count == 27
      assert since_five_days_ago_respondents_count == 45
    end

    test "filter by disposition and since", %{
      now: now,
      total_respondents_count: total_respondents_count
    } do
      queued_yesterday_filter_where = disposition_since_days_ago_filter_where("queued", now, 1)

      started_three_days_ago_filter_where =
        disposition_since_days_ago_filter_where("started", now, 3)

      contacted_five_days_ago_filter_where =
        disposition_since_days_ago_filter_where("contacted", now, 5)

      queued_yesterday_respondents_count =
        filter_respondents_and_count(queued_yesterday_filter_where)

      started_three_days_ago_respondents_count =
        filter_respondents_and_count(started_three_days_ago_filter_where)

      contacted_five_days_ago_respondents_count =
        filter_respondents_and_count(contacted_five_days_ago_filter_where)

      assert total_respondents_count == 45
      assert queued_yesterday_respondents_count == 1
      assert started_three_days_ago_respondents_count == 9
      assert contacted_five_days_ago_respondents_count == 24
    end
  end

  # These tests cover that filtering by parsed since works
  describe "filter by since parsing it" do
    setup do
      # prepare the dates
      dummy_date = Timex.parse!("2020-06-01", "{YYYY}-{0M}-{0D}")
      two_days_after = Timex.shift(dummy_date, days: 2)
      # prepare the respondents
      for _ <- 1..2, do: insert(:respondent, disposition: "queued", updated_at: dummy_date)
      for _ <- 1..3, do: insert(:respondent, disposition: "queued", updated_at: two_days_after)

      {
        :ok,
        total_respondents_count: count_all_respondents()
      }
    end

    test "support an ISO 8601 date", %{
      total_respondents_count: total_respondents_count
    } do
      day_between = "2020-06-02"

      since_day_between_respondents_count = parse_since_filter_and_count(day_between)

      assert total_respondents_count == 5
      assert since_day_between_respondents_count == 3
    end
  end

  # These tests try to cover the case where Surveda is being used by external services like
  # SurvedaOnaConnector
  # Before the repondents filter module existed, the "since" url param received in the respondent
  # controller was being applied directly. So the understanding of the received date format string
  # was delegated to Ecto
  # See: https://github.com/instedd/surveda-ona-connector
  # Details: lib/surveda_ona_connector/runtime/surveda_client.ex#L58-L66
  describe "filter by since without parsing it" do
    setup do
      # prepare the dates
      dummy_date = Timex.parse!("2020-06-01", "{YYYY}-{0M}-{0D}")
      two_days_after = Timex.shift(dummy_date, days: 2)
      # prepare the respondents
      for _ <- 1..2, do: insert(:respondent, disposition: "queued", updated_at: dummy_date)
      for _ <- 1..3, do: insert(:respondent, disposition: "queued", updated_at: two_days_after)

      {
        :ok,
        total_respondents_count: count_all_respondents()
      }
    end

    test "support a RFC 3339 5.6 date-time variation used by Ona connector", %{
      total_respondents_count: total_respondents_count
    } do
      # prepare the date in a format string that Ecto should handle properly
      day_between = "2020-06-02 00:20:56.000000Z"

      # put since directly (without parsing it), filter, and count
      since_day_between_respondents_count = put_since_filter_and_count(day_between)

      assert total_respondents_count == 5
      assert since_day_between_respondents_count == 3
    end

    test "support an ISO 8601 date-time variation", %{
      total_respondents_count: total_respondents_count
    } do
      # prepare the date in a format string that Ecto should handle properly
      day_between = "2020-06-02T19:20:30+01:00"

      # put since directly (without parsing it), filter, and count
      since_day_between_respondents_count = put_since_filter_and_count(day_between)

      assert total_respondents_count == 5
      assert since_day_between_respondents_count == 3
    end
  end

  # These tests try to cover the support for optimized queries used by the respondent controller
  # for generating the CSV results file
  # See https://github.com/instedd/surveda/commit/c812c676045debac25da816ba40f29ed5331b0a9
  describe "support optimized queries" do
    setup do
      # prepare the respondents
      for _ <- 1..2, do: insert(:respondent, disposition: "queued")
      for _ <- 1..3, do: insert(:respondent, disposition: "started")

      {
        :ok,
        total_respondents_count: count_all_respondents()
      }
    end

    test "filter using optimized queries", %{
      total_respondents_count: total_respondents_count
    } do
      optimized_filter_where = filter_where(:disposition, "queued", optimized: true)
      optimized_query = optimized_count_respondents_query(optimized_filter_where)

      filtered_respondents_count = Repo.one(optimized_query)
      optimized_sql = SQL.to_sql(:all, Repo, optimized_query)

      assert total_respondents_count == 5
      assert filtered_respondents_count == 2

      assert optimized_sql == {
               """
               SELECT count(r0.`id`)
                FROM `respondents` AS r0
                INNER JOIN `respondents` AS r1 ON r0.`id` = r1.`id`
                WHERE (TRUE AND (r1.`disposition` = ?))
               """
               |> String.replace("\n", ""),
               ["queued"]
             }
    end

    test "filter without using optimized queries", %{
      total_respondents_count: total_respondents_count
    } do
      filter_where = filter_where(:disposition, "queued")
      query = count_respondents_query(filter_where)

      filtered_respondents_count = Repo.one(query)
      sql = SQL.to_sql(:all, Repo, query)

      assert total_respondents_count == 5
      assert filtered_respondents_count == 2

      assert sql == {
               """
               SELECT count(r0.`id`)
                FROM `respondents` AS r0
                WHERE (TRUE AND (r0.`disposition` = ?))
               """
               |> String.replace("\n", ""),
               ["queued"]
             }
    end
  end

  defp parse_since_filter_and_count(date_time_string) do
    RespondentsFilter.parse_since(%RespondentsFilter{}, date_time_string)
    |> filter_and_count()
  end

  # Put since directly (without parsing it), filter, and count
  defp put_since_filter_and_count(date_time_string) do
    RespondentsFilter.put_since(%RespondentsFilter{}, date_time_string)
    |> filter_and_count()
  end

  defp filter_and_count(filter),
    do:
      filter
      |> RespondentsFilter.filter_where()
      |> filter_respondents_and_count()

  defp insert_respondents_set(now) do
    two_days_ago = Timex.shift(now, days: -2)
    four_days_ago = Timex.shift(now, days: -4)

    for _ <- 1..1,
        do:
          insert(:respondent, disposition: "queued", state: "pending", mode: ["sms", "sms", "ivr"])

    for _ <- 1..2,
        do:
          insert(:respondent,
            disposition: "queued",
            state: "pending",
            updated_at: two_days_ago,
            mode: ["ivr", "mobileweb", "mobileweb"]
          )

    for _ <- 1..3,
        do:
          insert(:respondent,
            disposition: "queued",
            state: "pending",
            updated_at: four_days_ago,
            mode: ["mobileweb", "sms", "sms"]
          )

    for _ <- 1..4, do: insert(:respondent, disposition: "started", state: "active", mode: ["sms"])

    for _ <- 1..5,
        do:
          insert(:respondent,
            disposition: "started",
            state: "active",
            updated_at: two_days_ago,
            mode: ["ivr"]
          )

    for _ <- 1..6,
        do:
          insert(:respondent,
            disposition: "started",
            state: "active",
            updated_at: four_days_ago,
            mode: ["mobileweb"]
          )

    for _ <- 1..7,
        do:
          insert(:respondent,
            disposition: "contacted",
            state: "cancelled",
            mode: ["sms", "ivr", "mobileweb"]
          )

    for _ <- 1..8,
        do:
          insert(:respondent,
            disposition: "contacted",
            state: "cancelled",
            updated_at: two_days_ago,
            mode: ["ivr", "ivr"]
          )

    for _ <- 1..9,
        do:
          insert(:respondent,
            disposition: "contacted",
            state: "cancelled",
            updated_at: four_days_ago,
            mode: ["mobileweb", "mobileweb"]
          )
  end

  defp disposition_since_days_ago_filter_where(disposition, now, days_ago),
    do:
      %RespondentsFilter{disposition: disposition, since: Timex.shift(now, days: -days_ago)}
      |> RespondentsFilter.filter_where()

  defp since_days_ago_filter_where(now, days_ago),
    do:
      %RespondentsFilter{since: Timex.shift(now, days: -days_ago)}
      |> RespondentsFilter.filter_where()

  defp filter_where(key, value, options \\ []) do
    optimized = Keyword.get(options, :optimized, false)

    Map.put(%RespondentsFilter{}, key, value)
    |> RespondentsFilter.filter_where(optimized: optimized)
  end

  defp count_all_respondents() do
    Repo.one(
      from(r in "respondents",
        select: count(r.id)
      )
    )
  end

  defp filter_respondents_and_count(filter_where),
    do:
      count_respondents_query(filter_where)
      |> Repo.one()

  defp count_respondents_query(filter_where),
    do:
      from(r in "respondents",
        where: ^filter_where,
        select: count(r.id)
      )

  defp optimized_count_respondents_query(filter_where),
    do:
      from(r in "respondents",
        join: r1 in "respondents",
        on: r.id == r1.id,
        where: ^filter_where,
        select: count(r.id)
      )
end
