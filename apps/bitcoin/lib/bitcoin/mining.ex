defmodule Bitcoin.Mining do
  @moduledoc """
  Module for mining  and related methods
  """
  import Bitcoin.Utilities.Crypto
  import Bitcoin.Utilities.Conversions

  def mine_async(candidate_block, bitcoin_node) do
    mined_block = initiate_mining(candidate_block)
    Bitcoin.Node.new_block_found(bitcoin_node, mined_block)
  end

  @doc """
  Initiate mining on a given `candidate_block`

  Returns the mined block which contains the nonce in its header for which the target was achieved
  """
  def initiate_mining(candidate_block) do
    target = Bitcoin.Structures.Block.calculate_target(candidate_block)
    IO.inspect("Starting to mine....")
    mine_block(candidate_block, target)
  end

  # mine_block
  # Calculates the nonce for which the `candidate_block` achieves the
  # difficulty target
  # 
  # Returns the mined block with the calculated nonce
  defp mine_block(candidate_block, target) do
    zeros_required = 32 - (String.trim_leading(target, <<0>>) |> byte_size)
    header = Bitcoin.Structures.Block.get_attr(candidate_block, :block_header)
    nonce = Bitcoin.Structures.Block.get_header_attr(candidate_block, :nonce)
    # IO.inspect(nonce)

    <<zeros_obtained_target::bytes-size(zeros_required), _::bits>> = target
    <<zeros_obtained_header::bytes-size(zeros_required), _::bits>> = header |> double_sha256

    hashed_value = header |> double_sha256
    v1 = binary_to_decimal(hashed_value)
    v2 = binary_to_decimal(target)

    if zeros_obtained_header == zeros_obtained_target and v1 <= v2 do
      IO.inspect("Done with mining....")
      IO.inspect(hashed_value)
      IO.inspect(target)
      IO.inspect(nonce)
      candidate_block
    else
      increment_nonce(candidate_block)
      |> mine_block(target)
    end
  end

  # increment_nonce
  # Increments the nonce in the candidate block header and returns the block
  #
  # Returns the block with updated nonce
  defp increment_nonce(candidate_block) do
    header = Bitcoin.Structures.Block.get_attr(candidate_block, :block_header)
    nonce = Bitcoin.Structures.Block.get_header_attr(candidate_block, :nonce)
    header = %Bitcoin.Schemas.BlockHeader{header | nonce: nonce + 1}
    candidate_block = %Bitcoin.Schemas.Block{candidate_block | block_header: header}
    candidate_block
  end
end
