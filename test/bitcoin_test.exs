defmodule BitcoinTest do
  use ExUnit.Case
  doctest Bitcoin

  test "greets the world" do
    assert Bitcoin.hello() == :world
  end
end
