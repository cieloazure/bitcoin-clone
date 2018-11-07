defmodule Transaction do
  # input:
  # transaction hash 	= all 0, 32 bytes
  # output index		= all 1, 4 bytes
  # coinbase data size	= length in bytes
  # coinbase data		= arbitraty data, must begin with block height
  # 	sequence number 	= set to 0xFFFFFFFF
  def create_generation_transaction(block_height, fees, recipient) do
    # transaction data:
    # block_hash
    # block_time
    # hex= ?? pg.187 Mastering bitcoin
    timestamp = DateTime.utc_now()

    # input:
    coinbase = "#{block_height},#{timestamp}"
    coinbase_size = byte_size(coinbase)
    sequence = 0xFFFFFFFF
    tx_hash = 0x00000000

    v_in = [
      coinbase: coinbase,
      sequence: sequence
    ]

    # output:
    value = Block.get_block_value(block_height, fees)

    v_out = [
      value: value,
      n: 0,
      address: recipient
    ]

    transaction = [
      v_in: v_in,
      v_out: v_out,
      time: timestamp
    ]

    tx_id = :crypto.hash(:sha256, inspect(transaction))

    transaction = [
      tx_id: tx_id,
      v_in: v_in,
      v_out: v_out,
      time: timestamp
    ]

    {:ok, transaction}
  end

  def create_transaction(block_height, fees, input_utxo, priv_key, recipient) do
  end
end
