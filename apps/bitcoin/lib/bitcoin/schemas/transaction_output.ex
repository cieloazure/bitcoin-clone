defmodule Bitcoin.Schemas.TransactionOutput do
  @moduledoc """
  A struct for transaction output
  """
  defstruct tx_id: nil, output_index: nil, amount: nil, locking_script: nil, address: nil

  @doc """
  Check whether the transaction output struct is valid
  """
  def valid?(output) do
    keys = Map.keys(output) |> List.delete_at(0)

    MapSet.equal?(
      MapSet.new(keys),
      MapSet.new([:tx_id, :output_index, :amount, :locking_script, :address])
    ) and valid_values?(output)
  end

  # Check whether the values present in the struct are valid
  defp valid_values?(output) do
    output = Map.from_struct(output)

    Enum.all?(output, fn {k, v} ->
      case k do
        :tx_id -> is_bitstring(v)
        :output_index -> is_number(v)
        :amount -> is_number(v) and v >= 0 and v < 21 * 1000_000 * 100_000_000
        :locking_script -> is_bitstring(v)
        :address -> is_bitstring(v) or is_nil(v)
      end
    end)
  end
end
