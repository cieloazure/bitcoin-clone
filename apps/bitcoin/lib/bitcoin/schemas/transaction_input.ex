defmodule Bitcoin.Schemas.TransactionInput do
  @moduledoc """
  A struct for transaction input
  """
  defstruct tx_id: nil, output_index: nil, unlocking_script_size: nil, unlocking_script: nil

  @doc """
  Check whether the transaction input struct is valid
  """
  def valid?(input) do
    keys = Map.keys(input) |> List.delete_at(0)

    MapSet.equal?(
      MapSet.new(keys),
      MapSet.new([:tx_id, :output_index, :unlocking_script_size, :unlocking_script])
    ) and valid_values?(input)
  end

  # Check whether the values present in the struct are valid
  defp valid_values?(input) do
    input = Map.from_struct(input)

    Enum.all?(input, fn {k, v} ->
      case k do
        :tx_id -> is_bitstring(v)
        :output_index -> is_number(v)
        :unlocking_script_size -> is_number(v) or is_nil(v)
        :unlocking_script -> is_bitstring(v)
      end
    end)
  end
end
