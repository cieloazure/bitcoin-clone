defmodule Bitcoin.Structures.Block do
  use Bitwise
  alias Bitcoin.Utilities.{MerkleTree, BloomFilter}
  import Bitcoin.Utilities.Crypto
  import Bitcoin.Utilities.Conversions

  @coin 100_000_000
  @halving_interval 210_000

  # Constants required to retarget a difficulty
  # In this case, the difficulty will be retargeted after
  # every block
  # It is also assumed that will take 60secs to generate a block
  # If the time required to produce one block is greater then the 
  # difficulty should increase else it should decrease
  @retarget_difficulty_after_blocks 1
  @expected_time_to_solve_one_block_in_secs 60

  @doc """
  Create the candidate genesis block for the blockchain
  """
  def create_candidate_genesis_block(
        difficulty \\ "1effffff",
        recipient \\ "<blockchain_creator/first_miner/satoshi_nakomoto>"
      ) do
    {:ok, gen_tx} = Bitcoin.Structures.Transaction.create_generation_transaction(0, 0, recipient)
    {merkle_root, merkle_tree} = MerkleTree.calculate_hash([gen_tx])

    bloom_filter = BloomFilter.init(50, 0.2) |> BloomFilter.put(Map.get(gen_tx, :tx_id))

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
      height: 0,
      merkle_tree: merkle_tree,
      bloom_filter: bloom_filter
    }
  end

  @doc """
  Create a candidate block for mining
  """
  def create_candidate_block(
        transaction_pool,
        blockchain,
        recipient \\ "<bitcoin-address-from-wallet>"
      ) do
    last_block = Bitcoin.Structures.Chain.top(blockchain)
    timestamp = DateTime.utc_now()
    height = get_attr(last_block, :height) + 1
    prev_block_hash = get_attr(last_block, :block_header) |> double_sha256
    version = 1

    # TODO: last_block may be equal to first_block
    bits =
      get_next_target(
        last_block,
        blockchain,
        @retarget_difficulty_after_blocks,
        @expected_time_to_solve_one_block_in_secs
      )

    initial_nonce = 1

    {:ok, gen_tx} =
      Bitcoin.Structures.Transaction.create_generation_transaction(
        height,
        0,
        recipient
      )

    transaction_pool = [gen_tx | transaction_pool]
    {merkle_root, merkle_tree} = MerkleTree.calculate_hash(transaction_pool)

    tx_ids = Enum.map(transaction_pool, fn tx -> Map.get(tx, :tx_id) end)
    bloom_filter = BloomFilter.init(50, 0.2) |> BloomFilter.put(tx_ids)

    header = %Bitcoin.Schemas.BlockHeader{
      version: version,
      timestamp: timestamp,
      prev_block_hash: prev_block_hash,
      nonce: initial_nonce,
      bits: bits,
      merkle_root: merkle_root
    }

    transaction_counter = length(transaction_pool)

    %Bitcoin.Schemas.Block{
      block_header: header,
      txns: transaction_pool,
      tx_counter: transaction_counter,
      height: height,
      merkle_tree: merkle_tree,
      bloom_filter: bloom_filter
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
  def calculate_target(block) do
    bits = get_header_attr(block, :bits)
    calculate_target_from_bits(bits)
  end

  @doc """
  Check the validity of the block
  """
  def valid?(block, chain) do
    with true <- valid_fields?(block),
         {true, is_genesis_block} <- valid_height?(block, chain),
         true <- valid_proof_of_work?(block, chain, is_genesis_block) do
      true
    else
      false ->
        false

      {false, _} ->
        false
    end
  end

  @doc """
  Check whether block contains the transaction referenced by the given input
  """
  def contains?(block, input) when is_map(input) do
    case not (Map.get(input, :tx_id) |> is_nil) do
      true ->
        BloomFilter.contains?(Map.get(block, :bloom_filter), Map.get(input, :tx_id))

      _ ->
        false
    end
  end

  @doc """
  Check whether block contains the transaction with given tx_id
  """
  def contains?(block, tx_id) do
    BloomFilter.contains?(Map.get(block, :bloom_filter), tx_id)
  end

  ### PRIVATE FUNCTIONS ###

  # Calculate target from a bitstring
  # For example, 
  # calculate_target_from_bits("1fffffff") will give <<0, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  # 0, 0, 0, 0, 0, 0, 0, 0>>
  defp calculate_target_from_bits(bits) when is_bitstring(bits) do
    {exponent, coeffiecient} = String.split_at(bits, 2)

    exponent = hex_to_decimal(exponent)
    coeffiecient = hex_to_decimal(coeffiecient)

    a = 8 * (exponent - 3)
    b = :math.pow(2, a)
    c = coeffiecient * b
    z = decimal_to_binary(c)
    target = String.pad_leading(z, 32, <<0>>)
    target
  end

  # Calculate the bitstring from a decimal target
  # For example, 
  # calculate_bits_from_target(:binary.decode_unsigned(<<0, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  # 0, 0, 0, 0, 0, 0, 0, 0>>)) will give "1FFFFFFF"
  def calculate_bits_from_target(new_target) when is_number(new_target) do
    new_target_bin = decimal_to_binary(new_target)
    new_target_bin = new_target_bin |> String.pad_leading(32, <<0>>)

    # Separate new target into coeffiecient and exponent
    new_target_coeffiecient_bin = String.trim(new_target_bin, <<0>>)
    new_target_coeffiecient_hex = binary_to_hex(new_target_coeffiecient_bin)

    b = :math.log2(new_target) - :math.log2(binary_to_decimal(new_target_coeffiecient_bin))

    new_target_exponent = b / 8 + 3
    new_target_exponent_bin = decimal_to_binary(new_target_exponent)
    new_target_exponent_hex = binary_to_hex(new_target_exponent_bin)

    new_target_exponent_hex <> new_target_coeffiecient_hex
  end

  # get_next_target
  #
  # Calculates the next target for the candidate block to achieve
  # The next target depends on how much time it takes for the block to mine
  # blocks in `retarget_difficulty_after_blockss` variable
  #
  # Returns the appropriate target for the block
  defp get_next_target(
         last_block,
         blockchain,
         retarget_difficulty_after_blocks,
         expected_time_to_solve_one_block_in_secs
       ) do
    last_target = get_header_attr(last_block, :bits)

    if length(blockchain) > retarget_difficulty_after_blocks do
      first_block =
        Bitcoin.Structures.Chain.sort(blockchain, :height)
        |> Enum.reverse()
        |> Enum.at(-retarget_difficulty_after_blocks)

      # calculate time difference
      time_difference =
        DateTime.diff(
          get_header_attr(last_block, :timestamp),
          get_header_attr(first_block, :timestamp),
          :nanoseconds
        )

      # Checking time difference
      # Because, a time_difference of 0 will make the new_target 0
      # And log of 0 will produce an error
      modifier =
        if trunc(time_difference) == 0 do
          # Keep the same difficulty if the time_difference is not even
          # registered in nanoseconds
          1
        else
          # nanoseconds to seconds
          time_difference = time_difference / :math.pow(10, 9)

          time_difference /
            (retarget_difficulty_after_blocks * expected_time_to_solve_one_block_in_secs)
        end

      target = calculate_target(last_block)

      # Calculate new target
      new_target = binary_to_decimal(target) * modifier

      # Calculate the new bits string 
      calculate_bits_from_target(new_target)
    else
      last_target
    end
  end

  # Check for validity of height of the block
  # Return a tuple to indicate whether the block is genesis_block
  # Tuple is of the form -> 
  # {validity, genesis_block_condition}
  defp valid_height?(block, confirmed_chain) do
    new_block_height = get_attr(block, :height)

    cond do
      new_block_height == 0 and Enum.empty?(confirmed_chain) ->
        {true, true}

      !Enum.empty?(confirmed_chain) ->
        top_block = Bitcoin.Structures.Chain.top(confirmed_chain)
        height = get_attr(top_block, :height)
        expected_height = height + 1
        {new_block_height <= expected_height and new_block_height > height, false}
    end
  end

  # Check for validity of the nonce of the block
  # Determines whether the difficulty has been solved for
  # Whether the puzzle is solved in order to provide proof of work
  defp valid_proof_of_work?(block, confirmed_chain, is_genesis_block) do
    expected_target =
      if !is_genesis_block do
        top_block = Bitcoin.Structures.Chain.top(confirmed_chain)

        get_next_target(
          top_block,
          confirmed_chain,
          @retarget_difficulty_after_blocks,
          @expected_time_to_solve_one_block_in_secs
        )
      else
        nil
      end

    target = get_header_attr(block, :bits)

    cond do
      is_genesis_block or target == expected_target ->
        difficulty = calculate_target_from_bits(target)
        difficulty = binary_to_decimal(difficulty)
        header = get_attr(block, :block_header)
        header_hash = double_sha256(header) |> binary_to_decimal()
        header_hash <= difficulty

      target != expected_target ->
        false
    end
  end

  # Check for validity of the fields of the block
  defp valid_fields?(block) do
    header = Map.get(block, :block_header)
    Bitcoin.Schemas.BlockHeader.valid?(header) and Bitcoin.Schemas.Block.valid?(block)
  end
end
