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

  @doc """
  Check whether the transaction struct is valid
  """
  def valid?(transaction) do
    keys = Map.keys(transaction) |> List.delete_at(0)

    MapSet.equal?(
      MapSet.new(keys),
      MapSet.new([:tx_id, :input_counter, :inputs, :output_counter, :outputs, :locktime, :version])
    ) and valid_values?(transaction)
  end

  # Check whether the values present in the struct are valid
  defp valid_values?(transaction) do
    transaction = Map.from_struct(transaction)

    Enum.all?(transaction, fn {k, v} ->
      case k do
        :tx_id ->
          is_bitstring(v)

        :input_counter ->
          is_number(v)

        :inputs ->
          is_list(v) and
            Enum.all?(v, fn input ->
              Bitcoin.Schemas.TransactionInput.valid?(input) or
                Bitcoin.Schemas.Coinbase.valid?(input)
            end)

        :output_counter ->
          is_number(v)

        :outputs ->
          is_list(v) and
            Enum.all?(v, fn output -> Bitcoin.Schemas.TransactionOutput.valid?(output) end)

        :locktime ->
          is_number(v) or is_nil(v)

        :version ->
          is_bitstring(v) or is_nil(v)
      end
    end)
  end
end
