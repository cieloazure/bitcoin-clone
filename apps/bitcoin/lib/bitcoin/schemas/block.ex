defmodule Bitcoin.Schemas.BlockHeader do
  @moduledoc """
  A module of the schema for block header. It has a one-to-one relationship with the Block
  """
  # @table_name "block_headers"
  defstruct prev_block_hash: nil,
            merkle_root: nil,
            timestamp: nil,
            nonce: nil,
            difficulty_target: nil
end

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
            txs: [],
            block_index: nil,
            hash: nil,
            height: nil
end
