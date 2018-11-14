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
            height: nil
end
