defmodule Bitcoin.Mining do
  def initiate_mining(candidate_block) do
    {_, zeros_required} = Bitcoin.Structures.Block.calculate_target(candidate_block)
    mine_block(candidate_block, zeros_required)
  end

  defp mine_block(candidate_block, zeros_required) do
    header = Bitcoin.Structures.Block.get_attr(candidate_block, :block_header)
    nonce = Bitcoin.Structures.Block.get_header_attr(candidate_block, :nonce)
    IO.inspect(nonce)

    <<zeros_obtained::bytes-size(zeros_required), _::bits>> =
      :erlang.term_to_binary(header) |> double_sha256

    if zeros_obtained == String.duplicate(<<0>>, zeros_required) do
      candidate_block
    else
      increment_nonce(candidate_block)
      |> mine_block(zeros_required)
    end
  end

  defp increment_nonce(candidate_block) do
    header = Bitcoin.Structures.Block.get_attr(candidate_block, :block_header)
    nonce = Bitcoin.Structures.Block.get_header_attr(candidate_block, :nonce)
    header = %Bitcoin.Schemas.BlockHeader{header | nonce: nonce + 1}
    candidate_block = %Bitcoin.Schemas.Block{candidate_block | block_header: header}
    candidate_block
  end

  defp double_sha256(data), do: sha256(data) |> sha256
  defp sha256(data), do: :crypto.hash(:sha256, data)
end
