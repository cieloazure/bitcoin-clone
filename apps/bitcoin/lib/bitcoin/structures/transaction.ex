defmodule Bitcoin.Structures.Transaction do
  alias Bitcoin.Utilities.ScriptUtil
  alias Bitcoin.Structures.Block
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
    value = Block.get_block_value(block_height, fees)

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

  def get_referenced_outputs(chain, inputs) do
    Enum.flat_map(inputs, fn input ->
      Enum.map(chain, fn block ->
        if Block.contains?(block, input) do
          Map.get(block, :txns)
          |> Enum.flat_map(fn tx -> Map.get(tx, :outputs) end)
          |> Enum.find(fn txo ->
            Map.get(txo, :tx_id) == Map.get(input, :tx_id) and
              Map.get(txo, :output_index) == Map.get(input, :output_index)
          end)
        end
      end)
    end)
    |> Enum.reject(fn element -> is_nil(element) end)
  end

  @doc """
  Check whether the given transaction output is unspent
  """
  def unspent_output?(tx_output, chain, tx_pool \\ []) do
    txo_id = Map.get(tx_output, :tx_id)
    txo_index = Map.get(tx_output, :output_index)

    try do
      # Get the subchain of blocks succeeding the block which contains given tx_output
      subchain =
        try do
          Enum.each(chain, fn block ->
            if Block.contains?(block, tx_output) do
              subchain =
                Bitcoin.Structures.Chain.get_blocks(chain, fn blk ->
                  Block.get_attr(blk, :height) >= Block.get_attr(block, :height)
                end)

              throw({:subchain, subchain})
            end
          end)

          # if execution reaches this point, it means the transaction referenced by
          # tx_output doesn't exist in the blockchain
          throw(:break)
        catch
          {:subchain, subchain} ->
            subchain
        end

      # Verify within the subchain whether tx_output has been used as a Transaction input
      Enum.each(subchain, fn block ->
        tx_inputs =
          Map.get(block, :txns)
          |> (fn txn -> if !is_list(txn), do: [txn], else: txn end).()
          |> Enum.flat_map(fn txn -> Map.get(txn, :inputs) end)

        if Enum.any?(tx_inputs, fn txi ->
             Map.get(txi, :tx_id) == txo_id and Map.get(txi, :output_index) == txo_index
           end),
           do: throw(:break)
      end)

      # Verify within current transaction pool whether tx_output has been used as a Transaction input
      Enum.each(tx_pool, fn txn ->
        tx_inputs = Map.get(txn, :inputs)

        if Enum.any?(tx_inputs, fn txi ->
             Map.get(txi, :tx_id) == txo_id and Map.get(txi, :output_index) == txo_index
           end),
           do: throw(:break)
      end)

      # Unspent tx_output 
      true
    catch
      :break -> false
    end
  end

  @doc """
  Check whether the total amount in the given list < 21 million satoshis
  """
  def valid_total?(list) when is_list(list) do
    try do
      Enum.reduce(list, 0, fn element, acc ->
        acc = acc + Map.get(element, :amount)

        if acc < 21 * 1000_000 * 100_000_000,
          do: acc,
          else: throw(:break)
      end)

      true
    catch
      :break -> false
    end
  end

  @doc """
  Check whether a transaction is valid.
  """
  def valid?(transaction, chain, transaction_pool, node) do
    # IO.puts("transaction")
    # IO.inspect(transaction)

    # IO.puts("chain")
    # IO.inspect(chain)
    inputs = Map.get(transaction, :inputs)
    referenced_outputs = get_referenced_outputs(chain, inputs)
    outputs = Map.get(transaction, :outputs)

    try do
      # 0. verify not a duplicate.
      if Enum.any?(chain, fn block -> Block.contains?(block, transaction) end) or
           Enum.any?(transaction_pool, fn txn -> Map.equal?(txn, transaction) end),
         do: throw(:break)

      # 1. verify structure
      if !Transaction.valid?(transaction),
        do: throw(:break)

      # 2. verify inputs and outputs are unique and not empty
      if Enum.empty?(inputs) or Enum.empty?(outputs),
        do: throw(:break)

      if length(Enum.dedup(inputs)) < length(inputs) or
           length(Enum.dedup(inputs)) < length(inputs),
         do: throw(:break)

      # 3. verify for each input, referenced output exists.
      # If not, put in orphan pool if matching transaction doesn't already exist.
      if length(referenced_outputs) < length(inputs) do
        send(
          node,
          {:orphan_transaction, transaction, get_unreferenced_inputs(inputs, referenced_outputs)}
        )

        throw(:break)
      end

      # 4. verify inputs and outputs' totals are: 0 <= total < 21m
      if !(valid_total?(referenced_outputs) and valid_total?(outputs)),
        do: throw(:break)

      # 5. verify standard form of locking and unlocking scripts
      # TODO:

      # 6. verify for each input, referenced output is unspent
      # 7. verify unlocking script validates against locking scripts.
      if !(Enum.zip(inputs, referenced_outputs)
           |> Enum.all?(fn {input, referenced_output} ->
             valid_input?(input, referenced_output, chain, transaction_pool)
           end)),
         do: throw(:break)

      # 8. reject if sum(outputs) > sum(inputs)
      sum_inputs =
        Enum.reduce(referenced_outputs, 0, fn ref_out, acc -> Map.get(ref_out, :amount) + acc end)

      sum_outputs = Enum.reduce(outputs, 0, fn output, acc -> Map.get(output, :amount) + acc end)

      if sum_outputs > sum_inputs, do: throw(:break)

      # 9. reject if transaction fee is too low to get into empty block
      # TODO:

      # all checks valid
      true
    catch
      :break -> false
    end
  end

  # Validate transaction inputs with their referenced outputs
  defp valid_input?(input, referenced_outputs, chain, transaction_pool) do
    try do
      # 7. verify unlocking script validates against locking scripts.
      script =
        ScriptUtil.join(
          Map.get(input, :unlocking_script),
          Map.get(referenced_outputs, :locking_script)
        )

      if !ScriptUtil.valid?(script),
        do: throw({:break, false})

      # 6. verify for each input, referenced output is unspent
      if !unspent_output?(referenced_outputs, chain, transaction_pool),
        do: throw({:break, false})

      throw({:break, true})
    catch
      {:break, result} ->
        result
    end
  end

  # Return list of inputs of an orphan transaction for which no reference_outputs were found
  defp get_unreferenced_inputs(inputs, referenced_outputs) do
    Enum.reject(inputs, fn input ->
      Enum.any?(referenced_outputs, fn ref_o ->
        Map.get(ref_o, :tx_id) == Map.get(input, :tx_id) and
          Map.get(ref_o, :output_index) == Map.get(input, :output_index)
      end)
    end)
  end
end
