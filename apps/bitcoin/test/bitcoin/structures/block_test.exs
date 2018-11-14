defmodule Bitcoin.Structures.BlockTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Block

  test "create a genesis candidate block" do
    # TODO: Verify correct genesis candidate block is obtained
    block = Block.create_candidate_genesis_block()
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
    {target, _zeros_required} = Block.calculate_target(block)

    assert Base.encode16(target) ==
             "0000000000000003A30C00000000000000000000000000000000000000000000"
  end

  describe "create candidate block" do
    test "target for the candidate block when chain is less than past_difficulty_param" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block()
      chain = [genesis_block]
      block = Bitcoin.Structures.Block.create_candidate_block([], chain)

      assert Bitcoin.Structures.Block.get_header_attr(block, :bits) ==
               Bitcoin.Structures.Block.get_header_attr(genesis_block, :bits)
    end

    test "target for the candidate block when the chain is greater than the past_difficulty_param" do
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block()
      Process.sleep(1000)
      chain = [genesis_block]
      block1 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      Process.sleep(1000)
      chain = [genesis_block, block1]
      block2 = Bitcoin.Structures.Block.create_candidate_block([], chain)

      assert Bitcoin.Structures.Block.get_header_attr(block2, :bits) !=
               Bitcoin.Structures.Block.get_header_attr(genesis_block, :bits)
    end
  end
end
