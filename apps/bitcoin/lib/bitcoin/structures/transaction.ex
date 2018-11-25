defmodule Bitcoin.Structures.Transaction do
  alias Bitcoin.Utilities.ScriptUtil
  alias Bitcoin.Schemas.{Transaction, TransactionInput, TransactionOutput}

  @doc """
  Create the generation transaction for a block with mining reward and transaction fees
  """
  def create_generation_transaction(block_height, fees, recipient) do
    tx_id = UUID.uuid4()
    timestamp = DateTime.utc_now()

    # input:
    coinbase = "#{block_height},#{timestamp}"
    # coinbase_size = byte_size(coinbase)
    sequence = 0xFFFFFFFF
    _tx_hash = 0x00000000

    v_in = %Bitcoin.Schemas.Coinbase{
      coinbase: coinbase,
      sequence: sequence
    }

    # output:
    value = Bitcoin.Structures.Block.get_block_value(block_height, fees)

    v_out = %TransactionOutput{
      tx_id: tx_id,
      output_index: 1,
      amount: value,
      locking_script: ScriptUtil.generate_locking_script(recipient)
      # address: recipient
    }

    transaction = %Transaction{
      tx_id: tx_id,
      input_counter: 1,
      inputs: [v_in],
      output_counter: 1,
      outputs: [v_out]
    }

    {:ok, transaction}
  end

  @doc """
  Create a new transaction with the given 'amount' (in satoshis), 'recipient'
  and unspent transaction outputs 'utxo'

  Returns '{:ok, transaction}'
  """
  def create_transaction(wallet, recipient, utxo, amount, fees \\ 0) do
    tx_id = UUID.uuid4()

    tx_inputs =
      Enum.map(utxo, fn t ->
        %TransactionInput{
          tx_id: Map.get(t, :tx_id),
          output_index: Map.get(t, :output_index),
          unlocking_script:
            ScriptUtil.generate_unlocking_script(wallet[:private_key], wallet[:public_key])
        }
      end)

    tx_out = %TransactionOutput{
      tx_id: tx_id,
      output_index: 1,
      amount: amount,
      locking_script: ScriptUtil.generate_locking_script(recipient)
    }

    change = Enum.reduce(utxo, 0, fn t, acc -> Map.get(t, :amount) + acc end) - amount - fees

    tx_change = %TransactionOutput{
      tx_id: tx_id,
      output_index: 2,
      amount: change,
      locking_script: ScriptUtil.generate_locking_script(wallet[:address])
    }

    tx_outputs = [tx_out, tx_change]

    transaction = %Transaction{
      tx_id: tx_id,
      input_counter: length(tx_inputs),
      inputs: tx_inputs,
      output_counter: length(tx_outputs),
      outputs: tx_outputs
    }

    {:ok, transaction}
  end

  @doc """
  Get the inputs required to transfer the given amount from user's unspent transaction outputs.
  """
  def get_required_inputs(utxo, amount) do
    [sum: _sum, list: tx_inputs] =
      Enum.reduce_while(utxo, [sum: 0, list: []], fn txo, acc ->
        if acc[:sum] < amount do
          sum = acc[:sum] + Map.get(txo, :amount)
          list = [txo | acc[:list]]

          {:cont, [sum: sum, list: list]}
        else
          {:halt, acc}
        end
      end)

    tx_inputs
  end

  @doc """
  Check whether the total amount in the given list < 21 million satoshis
  """
  def valid_total?(list) when is_list(list) do
    try do
      Enum.reduce(list, 0, fn element, acc ->
        # if element[:amount] > 0 and element[:amount] < 21 * 1000_000 * 100_000_000 do
        acc = acc + element[:amount]

        if acc < 21 * 1000_000 * 100_000_000,
          do: acc,
          else: throw(:break)

        # else
        #   throw(:break)
        # end
      end)

      true
    catch
      :break -> false
    end
  end

  @doc """
  Check whether the given transaction output is unspent
  """
  def unspent_output?(tx_output, sub_chain) do
    txo_hash = Map.get(tx_output, :tx_id)
    txo_index = Map.get(tx_output, :output_index)

    try do
      Enum.each(sub_chain, fn blk ->
        tx_inputs = Map.get(blk, :txns) |> Map.get(:inputs)

        for txi <- tx_inputs do
          txi_hash = Map.get(txi, :tx_id)
          txi_index = Map.get(txi, :output_index)

          if txi_hash == txo_hash and txi_index == txo_index,
            do: throw(:break)
        end
      end)
    catch
      :break -> false
    end

    true
  end
end
