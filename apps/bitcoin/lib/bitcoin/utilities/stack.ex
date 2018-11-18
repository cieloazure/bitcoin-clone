defmodule Bitcoin.Utilities.Stack do
  def push(stack, item) do
    [item | stack]
  end

  def pop(stack, depth \\ 1)

  def pop(stack, depth) when depth == 1 do
    List.pop_at(stack, 0)
  end

  def pop(stack, depth) do
    multipop(stack, depth, [])
  end

  defp multipop(stack, depth, items) when depth == 1 or length(stack) == 1 do
    {item, stack} = List.pop_at(stack, 0)
    items = [item | items]
    {Enum.reverse(items), stack}
  end

  defp multipop(stack, depth, items) do
    {item, stack} = List.pop_at(stack, 0)
    items = [item | items]
    multipop(stack, depth - 1, items)
  end

  def empty?(stack) do
    Enum.empty?(stack)
  end

  def size(stack) do
    length(stack)
  end

  def peek(stack, depth \\ 1)
  def peek(stack, _depth) when length(stack) == 0, do: nil
  def peek(stack, depth) when depth == 1, do: List.first(stack)

  def peek(stack, depth) when length(stack) > depth do
    Enum.take(stack, depth)
  end

  def peek(stack, _depth) do
    stack
  end
end
