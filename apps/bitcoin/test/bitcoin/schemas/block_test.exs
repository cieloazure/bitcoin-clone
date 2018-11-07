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
    {_, block} = Map.get_and_update(block, :block_index, fn item -> {item, 1} end)
    assert Map.get(block, :block_index) == 1
  end
end
