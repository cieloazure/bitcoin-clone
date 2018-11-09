defmodule Bitcoin.Blockchain.Block do
  use Bitwise

  @coin 100_000_000
  @halving_interval 210_000

  @doc """
  Create the genesis block for the blockchain
  """
  def create_genesis_block(recipient) do
    gen_tx = Bitcoin.Blockchain.Transaction.create_generation_transaction(0, 0, recipient)
    merkle_root = :crypto.hash(:sha256, gen_tx[:tx_id])

    previous_block_hash = <<0::256>>
    timestamp = DateTime.utc_now()
    nonce = nonce_calc(previous_block_hash, 2)

    header = %Bitcoin.Schemas.BlockHeader{
      prev_block_hash: previous_block_hash,
      merkle_root: merkle_root,
      timestamp: timestamp,
      nonce: nonce,
      difficulty_target: 2
    }

    block = %Bitcoin.Schemas.Block{
      block_header: header,
      # block_size: byte_size(block),
      tx_counter: 1,
      txs: [gen_tx],
      block_index: nil,
      hash: nil,
      height: 0
    }

    block = %{block | block_size: byte_size(block)}

    {:ok, block}
  end

  @doc """
  Create a block
  """
  def create_block(height, prev, nonce, difficulty, transactions, merkle_root) do
    header = %Bitcoin.Schemas.BlockHeader{
      prev_block_hash: prev,
      merkle_root: merkle_root,
      timestamp: DateTime.utc_now(),
      nonce: nonce,
      difficulty_target: difficulty
    }

    block = %Bitcoin.Schemas.Block{
      block_header: header,
      # block_size: 0,
      tx_counter: length(transactions),
      txs: transactions,
      block_index: nil,
      hash: nil,
      height: height
    }

    block = %{block | block_size: byte_size(block)}

    {:ok, block}
  end

  @doc """
  Calculate the amount to be rewarded to the miner
  """
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

  @doc """
  Calculate the nonce required to reach the specified difficulty target
  """
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
