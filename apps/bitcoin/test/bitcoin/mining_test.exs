defmodule Bitcoin.MiningTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Block

  test "mining a genesis block with fake difficulty" do
    genesis_block = Block.create_candidate_genesis_block()
    mined_block = Bitcoin.Mining.initiate_mining(genesis_block, 2)
    IO.inspect(mined_block)
    assert Block.get_header_attr(mined_block, :nonce) != 1

    header = Block.get_attr(mined_block, :block_header)

    <<zeros_obtained::bytes-size(2), _::bits>> = :erlang.term_to_binary(header) |> double_sha256

    assert zeros_obtained == String.duplicate(<<0>>, 2)
  end

  # test "mining a genesis block with real difficulty" do
  # genesis_block = Block.create_candidate_genesis_block()
  # mined_block = Bitcoin.Mining.initiate_mining(genesis_block)
  # IO.inspect(mined_block)
  # assert Block.get_header_attr(mined_block, :nonce) != 1

  # header = Block.get_attr(mined_block, :block_header)

  # <<zeros_obtained::bytes-size(2), _::bits>> = :erlang.term_to_binary(header) |> double_sha256

  # assert zeros_obtained == String.duplicate(<<0>>)
  # end

  test "mining a candidate block with fake difficulty" do
    genesis_block = Block.create_candidate_genesis_block()
    Process.sleep(1000)
    block1 = Block.create_candidate_block([], [genesis_block])
    mined_block = Bitcoin.Mining.initiate_mining(block1, 2)
    IO.inspect(mined_block)
    assert Block.get_header_attr(mined_block, :nonce) != 1

    header = Block.get_attr(mined_block, :block_header)

    <<zeros_obtained::bytes-size(2), _::bits>> = :erlang.term_to_binary(header) |> double_sha256

    assert zeros_obtained == String.duplicate(<<0>>, 2)
  end

  test "difficulty increases when blocks are mined quickly" do
    genesis_block = Block.create_candidate_genesis_block()
    prev_bits = Block.get_header_attr(genesis_block, :bits)
    mined_block = Bitcoin.Mining.initiate_mining(genesis_block, 2)
    chain = [mined_block]
    block1 = Block.create_candidate_block([], chain)
    mined_block = Bitcoin.Mining.initiate_mining(block1, 1)
    chain = [mined_block | chain]
    block2 = Block.create_candidate_block([], chain)
    _mined_block = Bitcoin.Mining.initiate_mining(block2, 1)
    bits = Block.get_header_attr(block2, :bits)
    IO.inspect(bits)
    {target, zeros_req} = calculate_target(bits)
    {prev_target, prev_zeros_req} = calculate_target(prev_bits)
    IO.inspect(prev_target)
    IO.inspect(target)
    IO.inspect(prev_zeros_req)
    IO.inspect(zeros_req)
    assert zeros_req >= prev_zeros_req
  end

  test "difficulty decreases when blocks are mined slowly" do
    genesis_block = Block.create_candidate_genesis_block()
    prev_bits = Block.get_header_attr(genesis_block, :bits)
    mined_block = Bitcoin.Mining.initiate_mining(genesis_block, 2)
    chain = [mined_block]
    Process.sleep(2000)
    block1 = Block.create_candidate_block([], chain)
    mined_block = Bitcoin.Mining.initiate_mining(block1, 2)
    chain = [mined_block | chain]
    Process.sleep(2000)
    block2 = Block.create_candidate_block([], chain)
    _mined_block = Bitcoin.Mining.initiate_mining(block2, 2)
    bits = Block.get_header_attr(block2, :bits)
    IO.inspect(bits)
    {target, zeros_req} = calculate_target(bits)
    {prev_target, prev_zeros_req} = calculate_target(prev_bits)
    IO.inspect(prev_target)
    IO.inspect(target)
    IO.inspect(prev_zeros_req)
    IO.inspect(zeros_req)
    assert zeros_req <= prev_zeros_req
  end

  defp double_sha256(data), do: sha256(data) |> sha256
  defp sha256(data), do: :crypto.hash(:sha256, data)

  defp calculate_target(bits) do
    {exponent, coeffiecient} = String.split_at(bits, 2)

    {:ok, exponent} = String.upcase(exponent) |> Base.decode16(case: :upper)
    {:ok, coeffiecient} = String.upcase(coeffiecient) |> Base.decode16(case: :upper)

    a = 8 * (:binary.decode_unsigned(exponent) - 3)
    b = :math.pow(2, a)
    c = :binary.decode_unsigned(coeffiecient) * b
    z = :binary.encode_unsigned(trunc(c), :big)
    target = String.pad_leading(z, 32, <<0>>)
    zeros_required = 32 - byte_size(z)
    {target, zeros_required}
  end
end
