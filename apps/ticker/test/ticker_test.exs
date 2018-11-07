defmodule TickerTest do
  use ExUnit.Case
  doctest Ticker

  test "greets the world" do
    assert Ticker.hello() == :world
  end
end
