defmodule Bitcoin.Schemas.Block do
  @moduledoc """
  A module of the schema for block. It has following relationships - 
  * One-to-one with the BlockHeader
  * One-to-many with Transactions
  """
  # @table_name  "blocks"
  defstruct block_header: %Bitcoin.Schemas.BlockHeader{},
            tx_counter: 0,
            txns: [],
            height: nil,
            merkle_tree: nil,
            bloom_filter: nil


  @doc """
  Check whether the block struct is valid
  """
  def valid?(block) do
    keys = Map.keys(block) |> List.delete_at(0)

    MapSet.equal?(
      MapSet.new(keys),
      MapSet.new([:block_header, :tx_counter, :txns, :height, :merkle_tree, :bloom_filter])
    ) and valid_values?(block)
  end

  # Check whether the values present in the struct are valid 
  defp valid_values?(block) do
    block = Map.from_struct(block)

    Enum.all?(block, fn {k, v} ->
      case k do
        :block_header -> is_map(v)
        :tx_counter -> is_number(v)
        :txns -> is_list(v)
        :height -> is_number(v)
        :merkle_tree -> is_map(v)
        :bloom_filter -> is_list(v)
      end
    end)
  end
end
