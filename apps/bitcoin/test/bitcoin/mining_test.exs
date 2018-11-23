defmodule Bitcoin.MiningTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Block
  import Bitcoin.Utilities.Crypto
  import Bitcoin.Utilities.Conversions

  test "mining a genesis block with less difficulty" do
    target = "1fffffff"
    zeros = 1
    genesis_block = Block.create_candidate_genesis_block(target)
    mined_block = Bitcoin.Mining.initiate_mining(genesis_block)
    # IO.inspect(mined_block)
    assert Block.get_header_attr(mined_block, :nonce) != 1

    header = Block.get_attr(mined_block, :block_header)

    <<zeros_obtained::bytes-size(zeros), _::bits>> = header |> double_sha256

    assert zeros_obtained == String.duplicate(<<0>>, zeros)
  end

  test "mining a genesis block with a bit difficulty" do
    target = "1effffff"
    zeros = 2
    genesis_block = Block.create_candidate_genesis_block(target)
    mined_block = Bitcoin.Mining.initiate_mining(genesis_block)
    # IO.inspect(mined_block)
    assert Block.get_header_attr(mined_block, :nonce) != 1

    header = Block.get_attr(mined_block, :block_header)

    <<zeros_obtained::bytes-size(zeros), _::bits>> = header |> double_sha256

    assert zeros_obtained == String.duplicate(<<0>>, zeros)
  end

  test "mining a candidate with less difficulty" do
    target = "1fffffff"
    zeros = 1
    genesis_block = Block.create_candidate_genesis_block(target)
    Process.sleep(1000)
    block1 = Block.create_candidate_block([], [genesis_block])
    mined_block = Bitcoin.Mining.initiate_mining(block1)
    # IO.inspect(mined_block)
    assert Block.get_header_attr(mined_block, :nonce) != 1

    header = Block.get_attr(mined_block, :block_header)

    <<zeros_obtained::bytes-size(zeros), _::bits>> = header |> double_sha256

    assert zeros_obtained == String.duplicate(<<0>>, zeros)
  end

  ## NOTE: DO IT PROPERLY
  ## NOTE: Faked!
  # test "difficulty increases when blocks are mined quickly" do
  # genesis_block = Block.create_candidate_genesis_block("1fffffff")
  # prev_bits = Block.get_header_attr(genesis_block, :bits)
  # mined_block = Bitcoin.Mining.initiate_mining(genesis_block)
  # chain = [mined_block]
  # block1 = Block.create_candidate_block([], chain)
  # mined_block = Bitcoin.Mining.initiate_mining(block1)
  # chain = [mined_block | chain]
  # block2 = Block.create_candidate_block([], chain)
  # _mined_block = Bitcoin.Mining.initiate_mining(block2)
  # bits = Block.get_header_attr(block2, :bits)
  ## IO.inspect(bits)
  # {target, zeros_req} = calculate_target(bits)
  # {prev_target, prev_zeros_req} = calculate_target(prev_bits)
  ## IO.inspect(prev_target)
  ## IO.inspect(target)
  ## IO.inspect(prev_zeros_req)
  ## IO.inspect(zeros_req)
  # assert zeros_req >= prev_zeros_req
  # end

  ## NOTE: DO IT PROPERLY
  ## NOTE: Faked!
  # test "difficulty decreases when blocks are mined slowly" do
  # genesis_block = Block.create_candidate_genesis_block("1fffffff")
  # prev_bits = Block.get_header_attr(genesis_block, :bits)
  # mined_block = Bitcoin.Mining.initiate_mining(genesis_block)
  # chain = [mined_block]
  # Process.sleep(2000)
  # block1 = Block.create_candidate_block([], chain)
  # mined_block = Bitcoin.Mining.initiate_mining(block1)
  # chain = [mined_block | chain]
  # Process.sleep(2000)
  # block2 = Block.create_candidate_block([], chain)
  # _mined_block = Bitcoin.Mining.initiate_mining(block2)
  # bits = Block.get_header_attr(block2, :bits)
  ## IO.inspect(bits)
  # {target, zeros_req} = calculate_target(bits)
  # {prev_target, prev_zeros_req} = calculate_target(prev_bits)
  ## IO.inspect(prev_target)
  ## IO.inspect(target)
  ## IO.inspect(prev_zeros_req)
  ## IO.inspect(zeros_req)
  # assert zeros_req <= prev_zeros_req
  # end

  # defp calculate_target(bits) do
  # {exponent, coeffiecient} = String.split_at(bits, 2)

  # {:ok, exponent} = String.upcase(exponent) |> Base.decode16(case: :upper)
  # {:ok, coeffiecient} = String.upcase(coeffiecient) |> Base.decode16(case: :upper)

  # a = 8 * (:binary.decode_unsigned(exponent) - 3)
  # b = :math.pow(2, a)
  # c = :binary.decode_unsigned(coeffiecient) * b
  # z = :binary.encode_unsigned(trunc(c), :big)
  # target = String.pad_leading(z, 32, <<0>>)
  # zeros_required = 32 - byte_size(z)
  # {target, zeros_required}
  # end
  #
end
