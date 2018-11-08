defmodule Helpers.CircularInterval do
  @moduledoc """
  Helpers.CircularInterval

  Has some utility functios to check whether the node lies in the circular list 

  Half open interval (a, b] -> includes range of numbers from a+1 to b
  Full open interval (a, b) -> includes range of numbers from a+1 to b-1

  The range wraps around the circle
  For example: Consider the identifier space module 2^3 = 8
  (1, 5) -> {2,3,4}
  (1, 5] -> {2,3,4,5}
  (5, 3) -> {6,7,8,1,2}
  (5, 3] -> {6,7,8,1,2,3}
  """
  require Logger

  @doc """
  Helpers.CircularInterval.half_open_interval_check

  Check whether `arg` lies in the half open interval of (`lower_limit`, `upper_limit`]

  Returns boolean `true` if it lies in the interval  or `false` if it doesn't lie in the interval
  """
  def half_open_interval_check(arg, lower_limit, upper_limit) do
    arg = if is_binary(arg), do: :crypto.bytes_to_integer(arg), else: arg

    lower_limit =
      if is_binary(lower_limit), do: :crypto.bytes_to_integer(lower_limit), else: lower_limit

    upper_limit =
      if is_binary(upper_limit), do: :crypto.bytes_to_integer(upper_limit), else: upper_limit

    cond do
      arg == upper_limit ->
        true

      lower_limit == upper_limit ->
        true

      lower_limit < upper_limit ->
        arg > lower_limit and arg <= upper_limit

      lower_limit > upper_limit ->
        arg > lower_limit or arg <= upper_limit

      true ->
        false
    end
  end

  @doc """
  Helpers.CircularInterval.open_interval_check

  A function to check to whether `arg` lies in the open interval of (lower_limit, upper_limit)

  Returns boolean `true` if it does lie in the interval and `false` if it doesn't 
  """
  def open_interval_check(arg, lower_limit, upper_limit) do
    arg = if is_binary(arg), do: :crypto.bytes_to_integer(arg), else: arg

    lower_limit =
      if is_binary(lower_limit), do: :crypto.bytes_to_integer(lower_limit), else: lower_limit

    upper_limit =
      if is_binary(upper_limit), do: :crypto.bytes_to_integer(upper_limit), else: upper_limit

    cond do
      lower_limit == upper_limit ->
        true

      lower_limit < upper_limit ->
        arg > lower_limit and arg < upper_limit

      lower_limit > upper_limit ->
        arg > lower_limit or arg < upper_limit

      true ->
        false
    end
  end
end
