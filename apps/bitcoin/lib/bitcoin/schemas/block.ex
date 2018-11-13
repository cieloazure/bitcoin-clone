defmodule Bitcoin.Schemas.Block do
  @moduledoc """
  A module of the schema for block. It has following relationships - 
  * One-to-one with the BlockHeader
  * One-to-many with Transactions
  """
  # @table_name  "blocks"
  defstruct block_header: %Bitcoin.Schemas.BlockHeader{},
            block_size: 0,
            tx_counter: 0,
            txns: [],
            block_index: nil,
            height: nil
end
