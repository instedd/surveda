defmodule Ask.PQueueTest do
  use ExUnit.Case
  alias Ask.PQueue

  test "push and pop" do
    queue =
      PQueue.new()
      |> PQueue.push(1, :low)
      |> PQueue.push(2, :high)
      |> PQueue.push(3, :normal)
    refute PQueue.empty?(queue)

    assert {queue, 2} = PQueue.pop(queue)
    assert {queue, 3} = PQueue.pop(queue)
    assert {queue, 1} = PQueue.pop(queue)
    assert {^queue, nil} = PQueue.pop(queue)
    assert PQueue.empty?(queue)
  end

  test "delete" do
    queue = PQueue.new()
    assert queue == queue |> PQueue.delete(fn _ -> raise "unreachable" end)

    queue =
      PQueue.new()
      |> PQueue.push(1, :high)
      |> PQueue.push(2, :low)
      |> PQueue.push(3, :normal)

    q1 = PQueue.delete(queue, fn item -> item == 1 end)
    refute PQueue.any?(q1, fn item -> item == 1 end)
    assert PQueue.any?(q1, fn item -> item == 2 end)
    assert PQueue.any?(q1, fn item -> item == 3 end)

    q2 = PQueue.delete(queue, fn item -> item == 2 end)
    assert PQueue.any?(q2, fn item -> item == 1 end)
    refute PQueue.any?(q2, fn item -> item == 2 end)
    assert PQueue.any?(q2, fn item -> item == 3 end)

    q3 = PQueue.delete(queue, fn item -> item == 3 end)
    assert PQueue.any?(q3, fn item -> item == 1 end)
    assert PQueue.any?(q3, fn item -> item == 2 end)
    refute PQueue.any?(q3, fn item -> item == 3 end)
  end

  test "each" do
    assert :ok == PQueue.new() |> PQueue.each(fn _ -> raise "unreachable" end)

    queue =
      PQueue.new()
      |> PQueue.push(1, :high)
      |> PQueue.push(2, :low)
      |> PQueue.push(3, :normal)

    # TODO: how to verify that the callback is really called?
    PQueue.each(queue, fn item ->
      assert item == 1 || item == 2 || item == 3
    end)
  end

  test "any?" do
    refute PQueue.new() |> PQueue.any?(fn _ -> raise "unreachable" end)

    queue =
      PQueue.new()
      |> PQueue.push(1, :high)
      |> PQueue.push(2, :low)
      |> PQueue.push(3, :normal)

    assert queue |> PQueue.any?(fn item -> item == 1 end)
    assert queue |> PQueue.any?(fn item -> item == 2 end)
    assert queue |> PQueue.any?(fn item -> item == 3 end)
    refute queue |> PQueue.any?(fn item -> item == 4 end)
  end

  test "empty?" do
    assert PQueue.new() |> PQueue.empty?()
    refute PQueue.new() |> PQueue.push(1, :high) |> PQueue.empty?()
    refute PQueue.new() |> PQueue.push(1, :normal) |> PQueue.empty?()
    refute PQueue.new() |> PQueue.push(1, :low) |> PQueue.empty?()
  end

  test "len" do
    queue = PQueue.new()
    assert 0 == PQueue.len(queue)

    assert 1 == PQueue.len(queue = PQueue.push(queue, 1, :high))
    assert 1 == PQueue.len(queue, :high)
    assert 0 == PQueue.len(queue, :normal)
    assert 0 == PQueue.len(queue, :low)

    assert 2 == PQueue.len(queue = PQueue.push(queue, 1, :high))
    assert 2 == PQueue.len(queue, :high)
    assert 0 == PQueue.len(queue, :normal)
    assert 0 == PQueue.len(queue, :low)

    assert 3 == PQueue.len(queue = PQueue.push(queue, 1, :normal))
    assert 2 == PQueue.len(queue, :high)
    assert 1 == PQueue.len(queue, :normal)
    assert 0 == PQueue.len(queue, :low)

    assert 4 == PQueue.len(queue = PQueue.push(queue, 1, :low))
    assert 2 == PQueue.len(queue, :high)
    assert 1 == PQueue.len(queue, :normal)
    assert 1 == PQueue.len(queue, :low)
  end
end
