defmodule Bitcoin.Schemas.BlockTest do
  use ExUnit.Case

  test "get defaults values in struct" do
    block = %Bitcoin.Schemas.Block{}
    assert !is_nil(block)
  end

  test "initialize the block with values" do
    block = %Bitcoin.Schemas.Block{block_index: 0, block_size: 10}
    assert Map.get(block, :block_index) == 0
    assert Map.get(block, :block_size) == 10
  end

  test "update the block with new values" do
    block = %Bitcoin.Schemas.Block{block_index: 0, block_size: 10}
    assert Map.get(block, :block_index) == 0
    {_, block} = Map.get_and_update(block, :block_index, fn item -> {item, 1} end)
    assert Map.get(block, :block_index) == 1
  end

  test "get a candidate block when only genesis block is present" do
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
end
