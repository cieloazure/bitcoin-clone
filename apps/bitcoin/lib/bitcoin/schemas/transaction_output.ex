defmodule Bitcoin.Schemas.TransactionOutput do
  @moduledoc """
  A struct for transaction output
  """
  defstruct tx_hash: nil, output_index: nil, amount: nil, locking_script: nil, address: nil
end
