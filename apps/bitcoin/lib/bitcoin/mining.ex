defmodule Bitcoin.Mining do
  import Bitcoin.Utilities.Crypto

  @moduledoc """
  Module for mining  and related methods
  """

  @doc """
  Initiate mining on a given `candidate_block`
  Difficulty can be "faked" by specifying the number of zeros required in `fake_number_of_zeros` parameter

  Returns the mined block which contains the nonce in its header for which the target was achieved
  """
  def initiate_mining(candidate_block, fake_number_of_zeros \\ nil) do
    {_, zeros_required} =
      Bitcoin.Structures.Block.calculate_target(candidate_block, fake_number_of_zeros)

    mine_block(candidate_block, zeros_required)
  end

  # mine_block
  # Calculates the nonce for which the `candidate_block` achieves the
  # difficulty target
  # 
  # Returns the mined block with the calculated nonce
  defp mine_block(candidate_block, zeros_required) do
    header = Bitcoin.Structures.Block.get_attr(candidate_block, :block_header)
    nonce = Bitcoin.Structures.Block.get_header_attr(candidate_block, :nonce)
    IO.inspect(nonce)

    <<zeros_obtained::bytes-size(zeros_required), _::bits>> = header |> double_sha256

    if zeros_obtained == String.duplicate(<<0>>, zeros_required) do
      candidate_block
    else
      increment_nonce(candidate_block)
      |> mine_block(zeros_required)
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
