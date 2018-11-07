defmodule Bitcoin.Schemas.BlockHeader do
  # @table_name "block_headers"
  #
  defstruct prev_block_hash: nil,
            merkle_root: nil,
            timestamp: nil,
            nonce: nil,
            difficulty_target: nil
end

defmodule Bitcoin.Schemas.Block do
  # @table_name  "blocks"

  defstruct block_size: 0,
            block_header: %Bitcoin.Schemas.BlockHeader{},
            tx_counter: 0,
            txs: [],
            block_index: nil,
            hash: nil
end
