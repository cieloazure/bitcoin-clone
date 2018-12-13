defmodule Bitcoin.Structures.Block do
  use Bitwise
  alias Bitcoin.Utilities.{MerkleTree, BloomFilter}
  require Logger
  import Bitcoin.Utilities.Crypto
  import Bitcoin.Utilities.Conversions

  @coin 100_000_000
  @halving_interval 210_000

  # Difficulty cannot exceed this number
  @proof_of_work_limit "1A0FFFFF"

  # Constants required to retarget a difficulty
  # In this case, the difficulty will be retargeted after
  # every 10 blocks
  # It is also assumed that will take 1secs to generate a block
  # If the time required to produce one block is greater then the 
  # difficulty should increase else it should decrease
  @retarget_difficulty_after_blocks 10
  @expected_time_to_solve_one_block_in_secs 30

  @doc """
  Create the candidate genesis block for the blockchain. A genesis block is the first block in any blockchain.
  The genesis block is usually mined separately from the rest of the blockchain and is hardcoded into the 
  application using which every node initializes the blockchain.

  Arguments:
    * difficulty: 
        - Determined the target bits for the genesis block
        - Has default value of "1EFFFFFF" which gives 2 zeros
    * recipient:
        - Determines who the genesis block belongs to, typically this will be done
          by the blockchain creator, although anyone can do it. Creating a genesis
          block is the first in starting the blockchain. Any new nodes or chain will
          always have the genesis block as their first block.
        - Has default value of - "<blockchain_creator/first_miner/satoshi_nakomoto>"

   Returns:
    * A genesis block which has not yet been mined. The block can be mined by calling
      `Bitcoin.Mining`
  """
  def create_candidate_genesis_block(
        difficulty \\ "1EFFFFFF",
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
  Arguments:
    * trasaction_pool: A List of transaction which have been heard by block up to this moment and to
      be inserted into the block
    * blockchain: A List of blocks using the reference of which the next candidate block is to be created
    * recipient: The recipient of the reward from this block. The recipient is the one who is mining the block
  Returns:
    * A candidate block of to mine next
  """
  def create_candidate_block(
        transaction_pool,
        blockchain,
        recipient \\ "<bitcoin-address-from-wallet>"
      )
      when is_list(transaction_pool) and is_list(blockchain) do
    last_block = Bitcoin.Structures.Chain.top(blockchain)
    timestamp = DateTime.utc_now()
    height = get_attr(last_block, :height) + 1
    prev_block_hash = get_attr(last_block, :block_header) |> double_sha256
    version = 1

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

  Arguments: 
    * height: Height of the block using which the block value is estimated
    * fees: The fees to be collected from transactions
  Returns:
    * Value of the block which is to be amount in the coinbase transaction of the block
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
  Get specific attribute of the block. Can get any attribute of the block mention in the schema

  Arguments:
    * block: The block who's attribute is to be fetched
    * attr: The attribute of the block required
  Returns:
    * The value of the attribute in the Block struct
  """
  def get_attr(block, _attr) when is_nil(block), do: nil
  def get_attr(block, attr), do: Map.get(block, attr)

  @doc """
  Get attribute of the block header

  Arguments:
    * block: The block who's header attribute is to be fetched
    * attr: The header attribute of the block required
  Returns:
    * The value of the attribute in the Block struct
  """
  def get_header_attr(block, attr), do: get_attr(block, :block_header) |> get_attr(attr)

  @doc """
  Calculate the target value required for mining from bits field of the header

  Arguments:
    * block: The block who's target is to be calculated
  """
  def calculate_target(block) do
    bits = get_header_attr(block, :bits)
    # IO.puts("Target bits are: #{bits}")
    calculate_target_from_bits(bits)
  end

  @doc """
  Check the validity of the block

  Argument:
    * block: The block who's validity is to be checked
    * chain: The current chain of the blockchain. Required to check for correctness of proof of work
  Returns:
    * Boolean value of `true` or `false` indicating whether the block is valid or not
  """
  def valid?(block, chain) do
    with true <- valid_fields?(block),
         {_, is_genesis_block} <- valid_height?(block, chain),
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
  def calculate_target_from_bits(bits) when is_bitstring(bits) do
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
  defp calculate_bits_from_target(new_target) when is_number(new_target) do
    new_target_bin = decimal_to_binary(new_target)
    <<first_byte::bytes-size(1), _::bits>> = new_target_bin

    new_target_bin =
      if first_byte > <<0x7F>> do
        <<0x00>> <> new_target_bin
      else
        new_target_bin
      end

    size = byte_size(new_target_bin) |> decimal_to_binary

    new_target_bin =
      if byte_size(new_target_bin) < 3 do
        String.pad_trailing(new_target_bin, 3, <<0x00>>)
      else
        new_target_bin
      end

    <<precision_bytes::bytes-size(3), _::bits>> = new_target_bin

    binary_to_hex(size <> precision_bytes)
  end

  # get_next_target
  #
  # Calculates the next target for the candidate block to achieve
  # The next target depends on how much time it takes for the block to mine
  # blocks in `retarget_difficulty_after_blockss` variable
  #
  # Arugments accepted:
  #   * last_block: The last block of the blockchain based on which the next
  #   target is to be calculated
  #   * blockchain: The chain in order to check whether difficulty is to be
  #   retargeted
  #
  # Returns the appropriate target for the block
  defp get_next_target(
         last_block,
         blockchain,
         retarget_difficulty_after_blocks,
         expected_time_to_solve_one_block_in_secs
       ) do
    last_target = get_header_attr(last_block, :bits) || "1EFFFFFF"
    height = get_attr(last_block, :height)

    if height != 0 and rem(height, retarget_difficulty_after_blocks) == 0 do
      first_block =
        Bitcoin.Structures.Chain.sort(blockchain, :height)
        |> Enum.at(-retarget_difficulty_after_blocks)

      # calculate time difference
      time_difference =
        DateTime.diff(
          get_header_attr(last_block, :timestamp),
          get_header_attr(first_block, :timestamp),
          :nanoseconds
        )

      # convert to secs
      time_difference = div(time_difference, trunc(:math.pow(10, 9)))

      # IO.puts("height: #{height}")
      # IO.puts("last 10th block height: #{inspect(get_attr(first_block, :height))}")
      # IO.puts("actual time diff: #{time_difference}")

      modifier =
        get_modifier(
          time_difference,
          expected_time_to_solve_one_block_in_secs * retarget_difficulty_after_blocks
        )

      # IO.puts("modifier: #{inspect(modifier)}")

      target = calculate_target_from_bits(get_header_attr(last_block, :bits))

      # Calculate new target
      new_target = binary_to_decimal(target) * modifier

      # Reaches proof of work limit
      new_target =
        if new_target > calculate_target_from_bits(@proof_of_work_limit) do
          calculate_target_from_bits(@proof_of_work_limit) |> binary_to_decimal
        else
          new_target
        end

      # Calculate the new bits string 
      calculate_bits_from_target(new_target)
    else
      last_target
    end
  end

  # Get modifier for retargeting
  #
  # In order to avoid fluctuations the new target shouldn't change by more 
  # than a factor of 4
  #
  # Returns the `modifier` to calculate new target with
  defp get_modifier(actual_timespan, target_timespan) do
    actual_timespan =
      cond do
        actual_timespan < div(target_timespan, 4) ->
          div(target_timespan, 4)

        actual_timespan > target_timespan * 4 ->
          target_timespan * 4

        true ->
          actual_timespan
      end

    actual_timespan / target_timespan
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
  # The fields should be present and in correct datatype
  defp valid_fields?(block) do
    header = Map.get(block, :block_header)
    Bitcoin.Schemas.BlockHeader.valid?(header) and Bitcoin.Schemas.Block.valid?(block)
  end

  # Check the validity of the transactions 
  # defp valid_transactions?(block, chain) do
  #! Enum.any?(get_attr(block, :txns), fn transaction -> 
  # Enum.any?(chain, fn block -> contains?(block, transaction) end)
  # end)
  # end
end
