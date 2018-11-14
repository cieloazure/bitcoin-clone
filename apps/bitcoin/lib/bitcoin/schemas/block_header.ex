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
end
