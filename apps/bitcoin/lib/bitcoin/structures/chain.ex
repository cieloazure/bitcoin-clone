defmodule Bitcoin.Structures.Chain do
  @moduledoc """
  Module to manipulate the chain. May be moved to the database in the future
  """
  alias Bitcoin.Structures.Block
  import Bitcoin.Utilities.Crypto

  @doc """
  Instantiate a new chain
  """
  def new_chain(genesis_block) do
    # Create a new collection of blocks or chain of blocks in the database of
    # the node 
    # Insert the genesis block as the the first record in the table
    # return the instance to that collection
    #
    # NOTE: Temoprarily implementing it in array or list, will change in the
    # future
    [genesis_block]
  end

  @doc """
  Get the topmost item of the chain
  Topmost item signifies the last block
  """
  def top(chain) do
    sort(chain, :height) |> List.last()
  end

  @doc """
  Save blocks in the chain
  """
  def save(chain, blocks) when is_list(blocks) do
    max_height_block = Enum.max_by(chain, fn block -> Block.get_attr(block, :height) end)

    missing_blocks =
      if !is_nil(max_height_block) do
        get_blocks(blocks, fn block ->
          Block.get_attr(block, :height) > Block.get_attr(max_height_block, :height)
        end)
      else
        blocks
      end

    missing_blocks ++ chain
  end

  @doc """
  Save a block in the chain
  """
  def save(chain, block) do
    [block | chain]
  end

  @doc """
  Get blocks
  """
  def get_blocks(chain, condition \\ nil)

  def get_blocks(chain, condition) when is_nil(condition) do
    chain
  end

  def get_blocks(chain, condition) do
    Enum.filter(chain, condition)
  end

  @doc """
  Sort the chain structure according to a field
  Field may be :height, :timestamp, etc/
  """
  def sort(chain, field) do
    Enum.sort(chain, fn block1, block2 ->
      Block.get_attr(block1, field) <= Block.get_attr(block2, field)
    end)
  end

  @doc """
  Fork a chain and return the new chain and forks
  """
  def fork(chain, new_block) do
    prev_block_hash = Block.get_header_attr(new_block, :prev_block_hash)

    block =
      Enum.find(chain, fn block ->
        prev_block_hash == Block.get_attr(block, :block_header) |> double_sha256
      end)

    {main_chain, fork} =
      Enum.split_with(chain, fn b ->
        Block.get_attr(b, :height) <= Block.get_attr(block, :height)
      end)

    forks = [fork, new_block]
    {main_chain, forks}
  end
end
