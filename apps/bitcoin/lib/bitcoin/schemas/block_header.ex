defmodule Bitcoin.Schemas.BlockHeader do
  @moduledoc """
  A module of the schema for block header. It has a one-to-one relationship with the Block
  """
  # @table_name "block_headers"
  defstruct prev_block_hash: nil,
            merkle_root: nil,
            timestamp: nil,
            nonce: nil,
            version: nil,
            bits: nil

  @doc """
  Check whether the block struct is valid
  """
  def valid?(header) do
    header_keys = Map.keys(header) |> List.delete_at(0)

    MapSet.equal?(
      MapSet.new(header_keys),
      MapSet.new([:prev_block_hash, :merkle_root, :timestamp, :version, :nonce, :bits])
    ) and valid_values?(header)
  end

  # Check whether the values present in the struct are valid 
  defp valid_values?(header) do
    header = Map.from_struct(header)

    Enum.all?(header, fn {k, v} ->
      case k do
        :prev_block_hash -> is_bitstring(v)
        :merkle_root -> is_bitstring(v)
        :timestamp -> DateTime.to_unix(v) |> is_number
        :version -> is_number(v)
        :nonce -> is_number(v)
        :bits -> is_bitstring(v)
      end
    end)
  end
end
