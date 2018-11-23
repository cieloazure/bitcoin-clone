defmodule Bitcoin.Utilities.StackTest do
  use ExUnit.Case

  alias Bitcoin.Utilities.Stack

  describe "push" do
    test "pushes an element in the stack" do
      stack = []
      stack = Stack.push(stack, {1, 1})
      assert stack == [{1, 1}]
    end
  end

  describe "empty?" do
    test "an actually empty stack" do
      stack = []
      assert Stack.empty?(stack)
    end

    test "not an empty stack" do
      stack = [{1, 1}]
      assert !Stack.empty?(stack)
    end
  end

  describe "size" do
    test "find size of empty stack" do
      stack = []
      assert Stack.size(stack) == 0
    end

    test "find size of non empty stack" do
      stack = [{1, 2}]
      assert Stack.size(stack) == 1
    end
  end

  describe "peek" do
    test "with default argument" do
      stack = []
      stack = Stack.push(stack, {1, 2})
      stack = Stack.push(stack, {2, 3})
      assert Stack.peek(stack) == {2, 3}
    end

    test "with depth of peek" do
      stack = []
      stack = Stack.push(stack, {1, 2})
      stack = Stack.push(stack, {2, 3})
      stack = Stack.push(stack, {6, 3})
      stack = Stack.push(stack, {2, 4})
      assert Stack.peek(stack, 2) == [{2, 4}, {6, 3}]
      assert Stack.peek(stack, 1) == {2, 4}
    end

    test "depth is greater than length of stack" do
      stack = []
      stack = Stack.push(stack, {1, 2})
      stack = Stack.push(stack, {2, 3})
      stack = Stack.push(stack, {6, 3})
      stack = Stack.push(stack, {2, 4})
      assert Stack.peek(stack, 50) == [{2, 4}, {6, 3}, {2, 3}, {1, 2}]
    end

    test "depth is greater than length of stack 2" do
      stack = []
      stack = Stack.push(stack, {1, 2})
      assert Stack.peek(stack, 2) == [{1, 2}]
    end

    test "peek on empty stack" do
      stack = []
      assert Stack.peek(stack) == nil
      assert Stack.peek(stack, 2) == nil
    end
  end

  describe "pop" do
    test "single pop without argument" do
      stack = []
      stack = Stack.push(stack, {1, 2})
      stack = Stack.push(stack, {2, 3})
      stack = Stack.push(stack, {6, 3})
      stack = Stack.push(stack, {2, 4})
      {elem, stack} = Stack.pop(stack)
      assert elem == {2, 4}
      assert stack == [{6, 3}, {2, 3}, {1, 2}]
    end

    test "single pop with argument" do
      stack = []
      stack = Stack.push(stack, {1, 2})
      stack = Stack.push(stack, {2, 3})
      stack = Stack.push(stack, {6, 3})
      stack = Stack.push(stack, {2, 4})
      {elem, stack} = Stack.pop(stack, 1)
      assert elem == {2, 4}
      assert stack == [{6, 3}, {2, 3}, {1, 2}]
    end

    test "multipop" do
      stack = []
      stack = Stack.push(stack, {1, 2})
      stack = Stack.push(stack, {2, 3})
      stack = Stack.push(stack, {6, 3})
      stack = Stack.push(stack, {2, 4})
      {elems, stack} = Stack.pop(stack, 2)
      assert elems == [{2, 4}, {6, 3}]
      assert stack == [{2, 3}, {1, 2}]
    end

    test "pop with an empty stack" do
      stack = []
      {elem, _stack} = Stack.pop(stack)
      assert is_nil(elem)
    end

    test "multipop more items than present in stack" do
      stack = []
      stack = Stack.push(stack, {1, 2})
      stack = Stack.push(stack, {2, 3})
      stack = Stack.push(stack, {6, 3})
      stack = Stack.push(stack, {2, 4})
      {elems, stack} = Stack.pop(stack, 60)
      assert elems == [{2, 4}, {6, 3}, {2, 3}, {1, 2}]
      assert length(stack) == 0
    end
  end
end
