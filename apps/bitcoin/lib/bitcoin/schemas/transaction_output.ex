defmodule Bitcoin.Schemas.TransactionOutput do
  @moduledoc """
  A struct for transaction output
  """
  defstruct tx_id: nil, output_index: nil, amount: nil, locking_script: nil, address: nil
end
