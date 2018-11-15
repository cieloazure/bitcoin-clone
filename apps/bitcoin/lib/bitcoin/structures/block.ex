defmodule Bitcoin.Structures.Block do
  use Bitwise

  @coin 100_000_000
  @halving_interval 210_000
  # @past_difficulty_param
  # Assuming, 60 secs for each block in the network
  @past_difficulty_param 1

  @doc """
  Create the candidate genesis block for the blockchain
  """
  def create_candidate_genesis_block(
        difficulty \\ "1D00FFFF",
        recipient \\ "<blockchain_creator/first_miner/satoshi_nakomoto>"
      ) do
    {:ok, gen_tx} = Bitcoin.Structures.Transaction.create_generation_transaction(0, 0, recipient)
    # merkle_root = :crypto.hash(:sha256, Map.get(gen_tx, :tx_id))
    merkle_root = nil

    previous_block_hash = <<0::256>>
    timestamp = DateTime.utc_now()
    nonce = 1

    header = %Bitcoin.Schemas.BlockHeader{
      prev_block_hash: previous_block_hash,
      merkle_root: merkle_root,
      timestamp: timestamp,
      nonce: nonce,
      bits: difficulty,
      version: 1
    }

    %Bitcoin.Schemas.Block{
      block_header: header,
      tx_counter: 1,
      txns: [gen_tx],
      height: 0
    }
  end

  @doc """
  Create a candidate block for mining
  """
  def create_candidate_block(transaction_pool, blockchain) do
    last_block = Bitcoin.Structures.Chain.top(blockchain)
    timestamp = DateTime.utc_now()
    height = get_attr(last_block, :height) + 1
    prev_block_hash = serialize(get_attr(last_block, :block_header)) |> double_sha256
    # merkle_root = Bitcoin.Utilities.MerkleTree.calculate_root(transaction_pool)
    version = 1
    # last_block may be equal to first_block
    bits = get_next_target(last_block, blockchain, @past_difficulty_param)
    initial_nonce = 1

    header = %Bitcoin.Schemas.BlockHeader{
      version: version,
      timestamp: timestamp,
      prev_block_hash: prev_block_hash,
      nonce: initial_nonce,
      bits: bits
      #      merkle_root: merkle_root,
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
  Get specific attribute of the block
  """
  def get_attr(block, _attr) when is_nil(block), do: nil
  def get_attr(block, attr), do: Map.get(block, attr)

  @doc """
  Get attribute of the block header
  """
  def get_header_attr(block, attr), do: get_attr(block, :block_header) |> get_attr(attr)

  @doc """
  Calculate the target value required for mining from bits field of the header
  """
  def calculate_target(block, zeros_required \\ nil) do
    bits = get_header_attr(block, :bits)
    {exponent, coeffiecient} = String.split_at(bits, 2)

    {:ok, exponent} = String.upcase(exponent) |> Base.decode16(case: :upper)
    {:ok, coeffiecient} = String.upcase(coeffiecient) |> Base.decode16(case: :upper)

    a = 8 * (:binary.decode_unsigned(exponent) - 3)
    b = :math.pow(2, a)
    c = :binary.decode_unsigned(coeffiecient) * b
    z = :binary.encode_unsigned(trunc(c), :big)
    target = String.pad_leading(z, 32, <<0>>)
    zeros_required = zeros_required || 32 - byte_size(z)
    {target, zeros_required}
  end

  ### PRIVATE FUNCTION ###

  # get_next_target
  #
  # Calculates the next target for the candidate block to achieve
  # The next target depends on how much time it takes for the block to mine
  # blocks in `past_difficulty_params` variable
  #
  # Returns the appropriate target for the block
  defp get_next_target(last_block, blockchain, past_difficulty_param) do
    last_target = get_header_attr(last_block, :bits)

    if length(blockchain) > past_difficulty_param do
      first_block =
        Bitcoin.Structures.Chain.sort(blockchain, :height)
        |> Enum.reverse()
        |> Enum.at(-past_difficulty_param)

      # calculate time difference
      time_difference =
        DateTime.diff(
          get_header_attr(last_block, :timestamp),
          get_header_attr(first_block, :timestamp)
        )

      # Calculate the new target in terms of bits
      modifier = time_difference / (past_difficulty_param * 60)

      {target, _} = calculate_target(last_block)

      new_target = :binary.decode_unsigned(target) * modifier

      new_target_bin =
        trunc(new_target) |> :binary.encode_unsigned() |> String.pad_leading(32, <<0>>)

      new_target_coeffiecient_bin = String.trim(new_target_bin, <<0>>)
      new_target_coeffiecient_hex = Base.encode16(new_target_coeffiecient_bin, case: :upper)

      b =
        :math.log2(new_target) - :math.log2(:binary.decode_unsigned(new_target_coeffiecient_bin))

      new_target_exponent = b / 8 + 3
      new_target_exponent_bin = :binary.encode_unsigned(trunc(new_target_exponent))
      new_target_exponent_hex = Base.encode16(new_target_exponent_bin, case: :upper)

      new_target_exponent_hex <> new_target_coeffiecient_hex
    else
      last_target
    end
  end

  # Helper functions to calculate SHA256 hash of the header
  # TODO: Move this in utilities
  defp double_sha256(data), do: sha256(data) |> sha256
  defp sha256(data), do: :crypto.hash(:sha256, data)

  # serialize
  #
  # Converts a elixir data structure to binary representation
  defp serialize(block), do: :erlang.term_to_binary(block)

  # @doc """
  # Check the validity of the block
  # """
  #
  # def valid?(block) do
  # end
end
