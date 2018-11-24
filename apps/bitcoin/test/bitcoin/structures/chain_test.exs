defmodule Bitcoin.Structures.ChainTest do
  use ExUnit.Case
  alias Bitcoin.Structures.{Chain, Block}
  import Bitcoin.Utilities.Crypto
  
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
      {min, max} = Enum.min_max_by(Enum.at(forks, 0), fn block -> Block.get_attr(block, :height) end)
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
