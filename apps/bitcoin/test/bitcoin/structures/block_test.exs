defmodule Bitcoin.Structures.BlockTest do
  test "create a genesis candidate block" do
  end

  test "create a candidate block when only genesis block is present in the blockchain" do
    {:ok, genesis_block} = Bitcoin.Structures.Block.get_genesis_block()
    block = Bitcoin.Structures.Block.create_candidate_block([], [genesis_block])
    assert !is_nil(block)
    header = Bitcoin.Structures.Block.get_attr(block, :block_header)
    assert !is_nil(Map.get(header, :timestamp))
    assert !is_nil(Map.get(header, :prev_block_hash))
    assert !is_nil(Map.get(header, :difficulty_target))
    assert !is_nil(Map.get(header, :nonce))
    genesis_block_height = Map.get(genesis_block, :height)
    assert Map.get(block, :height) == genesis_block_height + 1
    genesis_block_target = Map.get(genesis_block, :block_header) |> Map.get(:difficulty_target)
    assert Map.get(header, :difficulty_target) == genesis_block_target
  end

  test "create get a candidate block when blocks present are more than the required for difficulty target retargeting" do
    # {:ok, genesis_block} = Bitcoin.Structures.Block.get_genesis_block()
    # chain = [genesis_block]
    # chain = create_dummy_blockchain(chain)
    # block = Bitcoin.Structures.Block.create_candidate_block([], chain)

    # assert Bitcoin.Structures.Block.get_header_attr(block, :difficulty_target) !=
    # Bitcoin.Structures.Block.get_header_attr(genesis_block, :difficulty_target)
  end

  test "get value of the block" do
  end

  test "get attribute of the block" do
  end

  test "get header attribute of the block" do
  end

  test "calculate target for the block" do
  end

  describe "create candidate block" do
    test "target for the candidate block when chain is less than past_difficulty_param" do
    end

    test "target for the candidate block when the chain is greater than the past_difficulty_param" do
    end

    test "when only genesis_block is present in the blockchain" do
    end
  end

  defp create_dummy_blockchain(chain) when length(chain) < 5 do
    block = Bitcoin.Structures.Block.create_candidate_block([], chain)
    chain = [block | chain]
    create_dummy_blockchain(chain)
  end

  defp create_dummy_blockchain(chain) do
    chain
  end
end
