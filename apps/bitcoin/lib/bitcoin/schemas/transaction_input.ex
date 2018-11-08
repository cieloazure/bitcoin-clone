defmodule Bitcoin.Schemas.TransactionInput do
  @moduledoc """
  A struct for transaction input
  """
  defstruct tx_hash: nil, output_index: nil, unlocking_script_size: nil, unlocking_script: nil
end
