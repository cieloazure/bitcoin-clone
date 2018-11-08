defmodule Bitcoin.Schemas.TransactionOutput do
  @moduledoc """
  A struct for transaction output
  """
  defstruct amount: nil, locking_script: nil, address: nil
end
