defmodule Ask.QuotaBucketTest do
  use Ask.DataCase

  alias Ask.{QuotaBucket}

  describe "matches_condition?" do
    test "lower bound bucket matches any value less than the lower bound" do
      matches_lower_bound = QuotaBucket.matches_condition?("5", [nil, 18])
      assert matches_lower_bound

      matches_lower_bound = QuotaBucket.matches_condition?("5", [nil, "18"])
      assert matches_lower_bound
    end

    test "lower bound bucket matches on the same value than the lower bound" do
      matches_lower_bound = QuotaBucket.matches_condition?("18", [nil, 18])
      assert matches_lower_bound

      matches_lower_bound = QuotaBucket.matches_condition?("18", [nil, "18"])
      assert matches_lower_bound
    end

    test "lower bound bucket does not match any value greater than the lower bound" do
      matches_lower_bound = QuotaBucket.matches_condition?("19", [nil, 18])
      assert !matches_lower_bound

      matches_lower_bound = QuotaBucket.matches_condition?("19", [nil, "18"])
      assert !matches_lower_bound
    end

    test "upper bound bucket matches any value greater than the upper bound" do
      matches_upper_bound = QuotaBucket.matches_condition?("110", [100, nil])
      assert matches_upper_bound

      matches_upper_bound = QuotaBucket.matches_condition?("110", ["100", nil])
      assert matches_upper_bound
    end

    test "upper bound bucket matches on the same value than the upper bound" do
      matches_upper_bound = QuotaBucket.matches_condition?("100", [100, nil])
      assert matches_upper_bound

      matches_upper_bound = QuotaBucket.matches_condition?("100", ["100", nil])
      assert matches_upper_bound
    end

    test "upper bound bucket does not match any value less than the upper bound" do
      matches_upper_bound = QuotaBucket.matches_condition?("95", [100, nil])
      assert !matches_upper_bound

      matches_upper_bound = QuotaBucket.matches_condition?("95", ["100", nil])
      assert !matches_upper_bound
    end

    test "common bucket matches if value is contained in range" do
      matches_bucket = QuotaBucket.matches_condition?("95", [18, 100])
      assert matches_bucket

      matches_bucket = QuotaBucket.matches_condition?("95", ["18", "100"])
      assert matches_bucket
    end

    test "common bucket matches if value equals the lower bound" do
      matches_bucket = QuotaBucket.matches_condition?("18", [18, 100])
      assert matches_bucket

      matches_bucket = QuotaBucket.matches_condition?("18", ["18", "100"])
      assert matches_bucket
    end

    test "common bucket matches if value equals the upper bound" do
      matches_bucket = QuotaBucket.matches_condition?("100", [18, 100])
      assert matches_bucket

      matches_bucket = QuotaBucket.matches_condition?("100", ["18", "100"])
      assert matches_bucket
    end

    test "common bucket does not match if value its bigger than the defined range" do
      matches_bucket = QuotaBucket.matches_condition?("101", [18, 100])
      assert !matches_bucket

      matches_bucket = QuotaBucket.matches_condition?("101", ["18", "100"])
      assert !matches_bucket
    end

    test "common bucket does not match if value its smalled than the defined range" do
      matches_bucket = QuotaBucket.matches_condition?("17", [18, 100])
      assert !matches_bucket

      matches_bucket = QuotaBucket.matches_condition?("17", ["18", "100"])
      assert !matches_bucket
    end
  end
end
