defmodule Bitcoin.Blockchain.Transaction do
  @doc """
  Create the generation transaction for a block with mining reward and transaction fees
  """
  def create_generation_transaction(block_height, fees, recipient) do
    timestamp = DateTime.utc_now()

    # input:
    coinbase = "#{block_height},#{timestamp}"
    # coinbase_size = byte_size(coinbase)
    sequence = 0xFFFFFFFF
    # tx_hash = 0x00000000

    v_in = %Bitcoin.Schemas.Coinbase{
      coinbase: coinbase,
      sequence: sequence
    }

    # output:
    value = Bitcoin.Blockchain.Block.get_block_value(block_height, fees)

    v_out = %Bitcoin.Schemas.TransactionOutput{
      amount: value,
      locking_script: "DUP HASH160 #{recipient} EQUALVERIFY CHECKSIG",
      address: recipient
    }

    transaction = %Bitcoin.Schemas.Transaction{
      inputs: [v_in],
      output_counter: 1,
      outputs: [v_out]
    }

    tx_id = :crypto.hash(:sha256, inspect(transaction))

    transaction = %{transaction | tx_id: tx_id}

    {:ok, transaction}
  end

  # def create_transaction(block_height, fees, input_utxo, priv_key, recipient) do
  # end
end
