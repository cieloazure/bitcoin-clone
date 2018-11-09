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
