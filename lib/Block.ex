defmodule Block do
  use Bitwise

  @coin 100_000_000
  @halving_interval 210_000

  def create_genesis_block(transaction, recipient) do
    gen_tx = Transaction.create_generation_transaction(0, 0, recipient)
    merkle_root = :crypto.hash(:sha256, gen_tx[:tx_id])

    previous_block_hash = <<0::256>>
    timestamp = DateTime.utc_now()

    nonce = nonce_calc(previous_block_hash, 2)

    header = [
      height: 0,
      previous_block: previous_block_hash,
      merkle_root: merkle_root,
      timestamp: timestamp,
      # difficulty: 2,
      nonce: nonce
    ]

    transactions = [gen_tx]

    block = [
      header: header,
      tx_counter: length(transactions),
      transactions: transactions
    ]

    {:ok, block}
  end

  def create_block(height, prev, nonce, transactions, merkle_root) do
    # gen_tx = Transaction.create_generation_transaction(height, fees, recipient)
    header = [
      height: height,
      previous_block: prev,
      merkle_root: merkle_root,
      timestamp: DateTime.utc_now(),
      nonce: nonce
    ]

    block = [
      header: header,
      tx_counter: length(transactions),
      transactions: transactions
    ]

    {:ok, block}
  end

  def get_block_value(height, fees) do
    subsidy = 50 * @coin
    halvings = trunc(height / @halving_interval)

    subsidy =
      if halvings >= 64 do
        fees
      else
        fees + (subsidy >>> halvings)
      end

    subsidy
  end

  def nonce_calc(input, difficulty, nonce \\ 0) do
    string = input <> Integer.to_string(nonce)
    hash = :crypto.hash(:sha256, string)
    n_zeros = difficulty * 8

    nonce =
      if <<0::size(n_zeros)>> == :binary.part(hash, 0, difficulty) do
        nonce
      else
        nonce_calc(input, difficulty, nonce + 1)
      end

    nonce
  end
end
