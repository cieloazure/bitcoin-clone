require IEx

defmodule Bitcoin.Structures.Block do
  use Bitwise

  @coin 100_000_000
  @halving_interval 210_000
  @past_difficulty 3

  @doc """
  Create the genesis block for the blockchain

  This is a function to generate genesis block. Every node will start with this block.
  """
  def get_genesis_block() do
    # Bitcoin/Blockchain creator
    # Recipient is always decided
    recipient = "100000"
    {:ok, gen_tx} = Bitcoin.Structures.Transaction.create_generation_transaction(0, 0, recipient)
    merkle_root = :crypto.hash(:sha256, Map.get(gen_tx, :tx_id))

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
      txns: [gen_tx],
      block_index: nil,
      height: 0
    }

    block = %{block | block_size: 50}

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
      txns: transactions,
      block_index: nil,
      # hash: nil,
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

  @doc """
  Get specific attribute of the block
  """
  def get_attr(block, attr) do
    if !is_nil(block) do
      Map.get(block, attr)
    else
      nil
    end
  end

  def get_header_attr(block, attr), do: get_attr(block, :block_header) |> get_attr(attr)

  @doc """
  Create a candidate block
  """
  def create_candidate_block(transaction_pool, blockchain) do
    last_block = Bitcoin.Structures.Chain.top(blockchain)
    timestamp = DateTime.utc_now()
    height = get_attr(last_block, :height) + 1
    prev_block_hash = serialize(get_attr(last_block, :block_header)) |> double_sha256
    # merkle_root = Bitcoin.Utilities.MerkleTree.calculate_root(transaction_pool)
    version = 1
    difficulty_target = get_next_target(last_block, blockchain)
    initial_nonce = 1

    header = %Bitcoin.Schemas.BlockHeader{
      version: version,
      timestamp: timestamp,
      prev_block_hash: prev_block_hash,
      #      merkle_root: merkle_root,
      difficulty_target: difficulty_target,
      nonce: initial_nonce
    }

    # transaction_counter = Bitcoin.Structures.TransactionPool.count(transaction_pool)
    transaction_counter = 0

    %Bitcoin.Schemas.Block{
      block_header: header,
      txns: transaction_pool,
      tx_counter: transaction_counter,
      height: height
    }
  end

  # def valid?(block) do
  # end

  defp get_next_target(last_block, blockchain) do
    last_target = get_header_attr(last_block, :difficulty_target)

    if length(blockchain) > @past_difficulty do
      # Go back 2016 blocks in blockchain and get that block
      first_block = Enum.at(blockchain, -@past_difficulty)

      # calculate time difference
      time_difference =
        DateTime.diff(
          get_header_attr(last_block, :timestamp),
          get_header_attr(first_block, :timestamp)
        )

      # last_target * (time_difference/20160 mins)
      last_target * (time_difference / (@past_difficulty * 10 * 60))
    else
      last_target
    end
  end

  defp double_sha256(data), do: sha256(data) |> sha256
  defp sha256(data), do: :crypto.hash(:sha256, data)

  defp serialize(block), do: :erlang.term_to_binary(block)
  def get_header_attr(block, attr), do: get_attr(block, :block_header) |> get_attr(attr)
  # defp deserialize(block), do: :erlang.binary_to_term(block)
end
