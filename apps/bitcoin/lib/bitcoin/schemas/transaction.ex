defmodule Bitcoin.Schemas.TransactionInput do
  @moduledoc """
  A struct for transaction input
  """
  defstruct tx_hash: nil, output_index: nil, unlocking_script_size: nil, unlocking_script: nil
end

defmodule Bitcoin.Schemas.TransactionOutput do
  @moduledoc """
  A struct for transaction output
  """
  defstruct amount: nil, locking_script: nil, address: nil
end

defmodule Bitcoin.Schemas.Transaction do
  @moduledoc """
  A struct for transaction
  """
  defstruct tx_id: nil,
            input_counter: 0,
            inputs: [],
            output_counter: 0,
            outputs: [],
            locktime: nil,
            version: nil
end
