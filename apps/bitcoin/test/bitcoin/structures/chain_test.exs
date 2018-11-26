defmodule Bitcoin.Structures.ChainTest do
  use ExUnit.Case
  alias Bitcoin.Structures.{Chain, Block}
  import Bitcoin.Utilities.Crypto

  describe "new_chain" do
    test "when the genesis block is provided it will return a list with genesis block" do
      genesis_block = Block.create_candidate_genesis_block()
      chain =  Chain.new_chain(genesis_block)
      assert chain == [genesis_block]
    end

    test "when genesis block is not provided it will return a empty list" do
      assert Chain.new_chain() == []
    end
  end

  describe "top" do
    test "when more than one blocks are present it should return the block with maximum height" do
      genesis_block = Block.create_candidate_genesis_block()
      chain = Chain.new_chain(genesis_block)
      block = Block.create_candidate_block([], chain)
      chain = [block | chain]
      block = %Bitcoin.Schemas.Block{block | height: 2}
      chain = [block | chain]
      top_block = Chain.top(chain)
      assert Block.get_attr(top_block, :height) == 2
    end
  end

  describe "save" do
    test "when given a block it will save it in the chain" do
      genesis_block = Block.create_candidate_genesis_block()
      chain = Chain.new_chain(genesis_block)
      block = Block.create_candidate_block([], chain)
      chain = Chain.save(chain, block)
      assert chain == [block, genesis_block]
    end
  end

  describe "sort" do
    test "when given multiple block it will sort them according to height" do
      genesis_block = Block.create_candidate_genesis_block()
      chain = Chain.new_chain(genesis_block)
      block = Block.create_candidate_block([], chain)
      chain = [block | chain]
      block = %Bitcoin.Schemas.Block{block | height: 2}
      chain = [block | chain]
      chain = Chain.sort(chain, :height)
      assert Enum.map(chain, &Block.get_attr(&1, :height)) == [0,1,2]
    end
  end

  describe "fork" do
    test "correctly forks a lists" do
      chain = create_chain([], 6, nil, 0)
      prev_block = Enum.find(chain, fn block -> Block.get_attr(block, :height) == 3 end)

      new_block_h = %Bitcoin.Schemas.BlockHeader{
        prev_block_hash: double_sha256(Block.get_attr(prev_block, :block_header))
      }

      new_block = %Bitcoin.Schemas.Block{
        block_header: new_block_h,
        height: 4
      }

      {main_chain, forks} = Chain.fork(chain, new_block)
      assert length(forks) == 2
      {min, max} = Enum.min_max_by(main_chain, fn block -> Block.get_attr(block, :height) end)
      assert Block.get_attr(min, :height) == 0
      assert Block.get_attr(max, :height) == 3

      {min, max} =
        Enum.min_max_by(Enum.at(forks, 0), fn block -> Block.get_attr(block, :height) end)

      assert Block.get_attr(min, :height) == 4
      assert Block.get_attr(max, :height) == 5
      assert length(Enum.at(forks, 1)) == 1
    end
  end

  defp create_chain(chain, length, _, index) when index >= length do
    chain
  end

  defp create_chain(chain, length, last_block_header, index) do
    prev_block = last_block_header || <<0>>

    blockh = %Bitcoin.Schemas.BlockHeader{
      prev_block_hash: double_sha256(prev_block)
    }

    block = %Bitcoin.Schemas.Block{
      block_header: blockh,
      height: index
    }

    chain = [block | chain]
    create_chain(chain, length, blockh, index + 1)
  end
end
