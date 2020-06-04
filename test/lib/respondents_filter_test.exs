defmodule Ask.RespondentsFilterTest do
  import Ecto.Query, only: [from: 2]
  use Ask.ConnCase
  alias Ask.RespondentsFilter

  @dummy_disposition "my-disposition"
  @dummy_date "2020-06-02"

  setup_all do
    {:ok, %{date_format_string: RespondentsFilter.date_format_string()}}
  end

  describe "parsing" do
    test "parse disposition from q" do
      q = "disposition:#{@dummy_disposition}"

      filter = RespondentsFilter.parse(q)

      assert filter.disposition == @dummy_disposition
    end

    test "parse since from q", %{date_format_string: date_format_string} do
      q = "since:#{@dummy_date}"

      filter = RespondentsFilter.parse(q)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
    end

    test "parse since and disposition", %{date_format_string: date_format_string} do
      q = "since:#{@dummy_date} disposition:#{@dummy_disposition}"

      filter = RespondentsFilter.parse(q)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      assert filter.disposition == @dummy_disposition

      # change the arguments order
      q = "disposition:#{@dummy_disposition} since:#{@dummy_date}"

      filter = RespondentsFilter.parse(q)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      assert filter.disposition == @dummy_disposition
    end

    test "parse when irrelevant stuffs", %{date_format_string: date_format_string} do
      q = "foo disposition:#{@dummy_disposition} bar since:#{@dummy_date} baz"

      filter = RespondentsFilter.parse(q)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      assert filter.disposition == @dummy_disposition

      # change the arguments order
      q = "disposition:#{@dummy_disposition} foo bar since:#{@dummy_date}"

      filter = RespondentsFilter.parse(q)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      assert filter.disposition == @dummy_disposition
    end

    test "put disposition when empty" do
      filter = %RespondentsFilter{}

      filter = RespondentsFilter.put_disposition(filter, @dummy_disposition)

      assert filter.disposition == @dummy_disposition
      refute filter.since
    end

    test "put disposition when since", %{date_format_string: date_format_string} do
      filter = %RespondentsFilter{since: Timex.parse!(@dummy_date, date_format_string)}

      filter = RespondentsFilter.put_disposition(filter, @dummy_disposition)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      assert filter.disposition == @dummy_disposition
    end

    test "put disposition when exists", %{date_format_string: date_format_string} do
      filter = %RespondentsFilter{disposition: "old-disposition", since: Timex.parse!(@dummy_date, date_format_string)}

      filter = RespondentsFilter.put_disposition(filter, @dummy_disposition)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      assert filter.disposition == @dummy_disposition
    end

    test "parse since when empty", %{date_format_string: date_format_string} do
      filter = %RespondentsFilter{}

      filter = RespondentsFilter.parse_since(filter, @dummy_date)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      refute filter.disposition
    end

    test "parse since when disposition", %{date_format_string: date_format_string} do
      filter = %RespondentsFilter{disposition: @dummy_disposition}

      filter = RespondentsFilter.parse_since(filter, @dummy_date)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      assert filter.disposition == @dummy_disposition
    end

    test "parse since when exists", %{date_format_string: date_format_string} do
      filter = %RespondentsFilter{disposition: @dummy_disposition, since: Timex.parse!("2019-01-01", date_format_string)}

      filter = RespondentsFilter.parse_since(filter, @dummy_date)

      assert filter.since == Timex.parse!(@dummy_date, date_format_string)
      assert filter.disposition == @dummy_disposition
    end
  end

  describe "filtering" do
    setup do
      now = Timex.now()
      insert_respondents_set(now)
      {:ok, now: now}
    end

    test "filter by disposition" do
      queued_filter_where = disposition_filter_where("queued")
      started_filter_where = disposition_filter_where("started")
      contacted_filter_where = disposition_filter_where("contacted")

      total = count_all_respondents()
      queued = filter_respondents_and_count(queued_filter_where)
      started = filter_respondents_and_count(started_filter_where)
      contacted = filter_respondents_and_count(contacted_filter_where)

      assert total == 45
      assert queued == 6
      assert started == 15
      assert contacted == 24
    end

    test "filter by since", %{now: now} do
      yesterday_filter_where = since_days_ago_filter_where(now, 1)
      three_days_ago_filter_where = since_days_ago_filter_where(now, 3)
      five_days_ago_filter_where = since_days_ago_filter_where(now, 5)

      total = count_all_respondents()
      since_yesterday = filter_respondents_and_count(yesterday_filter_where)
      since_three_days_ago = filter_respondents_and_count(three_days_ago_filter_where)
      since_five_days_ago = filter_respondents_and_count(five_days_ago_filter_where)

      assert total == 45
      assert since_yesterday == 12
      assert since_three_days_ago == 27
      assert since_five_days_ago == 45
    end

    test "filter by disposition and since", %{now: now} do
      queued_yesterday_filter_where = disposition_since_days_ago_filter_where("queued", now, 1)
      started_three_days_ago_filter_where = disposition_since_days_ago_filter_where("started", now, 3)
      contacted_five_days_ago_filter_where = disposition_since_days_ago_filter_where("contacted", now, 5)

      total = count_all_respondents()
      queued_yesterday = filter_respondents_and_count(queued_yesterday_filter_where)
      started_three_days_ago = filter_respondents_and_count(started_three_days_ago_filter_where)
      contacted_five_days_ago = filter_respondents_and_count(contacted_five_days_ago_filter_where)

      assert total == 45
      assert queued_yesterday == 1
      assert started_three_days_ago == 9
      assert contacted_five_days_ago == 24
    end
  end

  defp insert_respondents_set(now) do
    two_days_ago = Timex.shift(now, days: -2)
    four_days_ago = Timex.shift(now, days: -4)

    for _ <- 1..1, do: insert(:respondent, disposition: "queued")
    for _ <- 1..2, do: insert(:respondent, disposition: "queued", updated_at: two_days_ago)
    for _ <- 1..3, do: insert(:respondent, disposition: "queued", updated_at: four_days_ago)
    for _ <- 1..4, do: insert(:respondent, disposition: "started")
    for _ <- 1..5, do: insert(:respondent, disposition: "started", updated_at: two_days_ago)
    for _ <- 1..6, do: insert(:respondent, disposition: "started", updated_at: four_days_ago)
    for _ <- 1..7, do: insert(:respondent, disposition: "contacted")
    for _ <- 1..8, do: insert(:respondent, disposition: "contacted", updated_at: two_days_ago)
    for _ <- 1..9, do: insert(:respondent, disposition: "contacted", updated_at: four_days_ago)
  end

  defp disposition_since_days_ago_filter_where(disposition, now, days_ago), do:
    %RespondentsFilter{disposition: disposition, since: Timex.shift(now, days: -days_ago)}
      |> RespondentsFilter.filter_where()

  defp since_days_ago_filter_where(now, days_ago), do:
    %RespondentsFilter{since: Timex.shift(now, days: -days_ago)}
    |> RespondentsFilter.filter_where()

  defp disposition_filter_where(disposition), do:
    %RespondentsFilter{disposition: disposition}
    |> RespondentsFilter.filter_where()

  defp count_all_respondents() do
    Repo.one(
        from r in "respondents",
        select: count(r.id)
      )
  end

  defp filter_respondents_and_count(filter_where) do
    Repo.one(
        from r in "respondents",
        where: ^filter_where,
        select: count(r.id)
      )
  end
end
