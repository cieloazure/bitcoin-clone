defmodule Bitcoin.Schemas.Coinbase do
  @moduledoc """
  A struct for coinbase inputs
  """
  defstruct coinbase: nil, sequence: nil

  @doc """
  Check whether the Coinbase input struct is valid
  """
  def valid?(input) do
    keys = Map.keys(input) |> List.delete_at(0)

    MapSet.equal?(
      MapSet.new(keys),
      MapSet.new([:coinbase, :sequence])
    ) and valid_values?(input)
  end

  # Check whether the values present in the struct are valid
  defp valid_values?(input) do
    input = Map.from_struct(input)

    Enum.all?(input, fn {k, v} ->
      case k do
        :coinbase -> is_bitstring(v)
        :sequence -> is_integer(v)
      end
    end)
  end
end
