defmodule Bitcoin.Structures.BlockTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Block

  test "create a genesis candidate block" do
    # TODO: Verify correct genesis candidate block is obtained
    block = Block.create_candidate_genesis_block()
    # IO.inspect(block)
    assert !is_nil(block)
  end

  test "get value of the block" do
  end

  test "get attribute of the block" do
    block = Block.create_candidate_genesis_block()
    assert Block.get_attr(block, :height) == 0
  end

  test "get header attribute of the block" do
    block = Block.create_candidate_genesis_block()
    assert Block.get_header_attr(block, :nonce) == 1
  end

  test "calculate target for the block" do
    block = Block.create_candidate_genesis_block("1903a30c")
    target = Block.calculate_target(block)

    assert Base.encode16(target) ==
             "0000000000000003A30C00000000000000000000000000000000000000000000"
  end

  describe "create candidate block" do
    test "target for the candidate block when chain is less than what is required for retarging" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block()
      chain = [genesis_block]
      block = Bitcoin.Structures.Block.create_candidate_block([], chain)

      assert Bitcoin.Structures.Block.get_header_attr(block, :bits) ==
               Bitcoin.Structures.Block.get_header_attr(genesis_block, :bits)
    end

    test "target for the candidate block when the chain is greater than the what is required for retargeting" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block()
      Process.sleep(1000)
      chain = [genesis_block]
      block1 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      block1 = %Bitcoin.Schemas.Block{block1 | height: 10}
      Process.sleep(1000)

      chain = [
        genesis_block,
        block1,
        block1,
        block1,
        block1,
        block1,
        block1,
        block1,
        block1,
        block1,
        block1
      ]

      block2 = Bitcoin.Structures.Block.create_candidate_block([], chain)

      assert Bitcoin.Structures.Block.get_header_attr(block2, :bits) !=
               Bitcoin.Structures.Block.get_header_attr(genesis_block, :bits)
    end
  end

  describe "check validity of block," do
    test "block data structure is syntactically valid" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block()
      genesis_block = Bitcoin.Mining.initiate_mining(genesis_block)
      chain = [genesis_block]
      block1 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      Process.sleep(1000)
      block1 = Bitcoin.Mining.initiate_mining(block1)
      assert Bitcoin.Structures.Block.valid?(block1, chain)
    end

    test "block data structure is not valid when a field is missing in block" do
      genesis_block =
        Bitcoin.Structures.Block.create_candidate_genesis_block() |> Map.delete(:height)

      chain = [genesis_block]

      Process.sleep(1000)
      assert !Bitcoin.Structures.Block.valid?(genesis_block, chain)
    end

    test "block data structure is not valid when a field is missing in block header" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block()
      header = Map.get(genesis_block, :block_header) |> Map.delete(:version)
      genesis_block = %{genesis_block | block_header: header}
      chain = [genesis_block]
      Process.sleep(1000)
      assert !Bitcoin.Structures.Block.valid?(genesis_block, chain)
    end

    test "genesis block has a valid nonce and its valid" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block("1effffff")
      mined_block = Bitcoin.Mining.initiate_mining(genesis_block)
      assert Bitcoin.Structures.Block.valid?(mined_block, [])
    end

    test "genesis block has a invalid nonce and is not valid" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block("1effffff")
      assert !Bitcoin.Structures.Block.valid?(genesis_block, [])
    end

    test "block has a valid nonce and its valid" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block("1effffff")
      mined_block = Bitcoin.Mining.initiate_mining(genesis_block)
      chain = [mined_block]
      block1 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      mined_block = Bitcoin.Mining.initiate_mining(block1)
      chain = [mined_block | chain]
      block2 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      mined_block = Bitcoin.Mining.initiate_mining(block2)
      assert Bitcoin.Structures.Block.valid?(mined_block, chain)
    end

    test "block has a invalid nonce and is valid" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block("1effffff")
      mined_block = Bitcoin.Mining.initiate_mining(genesis_block)
      chain = [mined_block]
      block1 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      mined_block = Bitcoin.Mining.initiate_mining(block1)
      chain = [mined_block | chain]
      block2 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      assert !Bitcoin.Structures.Block.valid?(block2, chain)
    end
  end
end
