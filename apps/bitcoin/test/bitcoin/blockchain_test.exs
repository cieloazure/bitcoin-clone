defmodule Bitcoin.BlockchainTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Block

  test "initialize the blockchain with genesis block" do
    {:ok, seed} = SeedServer.start_link([])
    genesis_block = Block.create_candidate_genesis_block()

    {:ok, node} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

    blockchain = :sys.get_state(node)[:blockchain]
    {n, {g, _,_}} = :sys.get_state(blockchain)
    assert node == n
    assert List.first(g) == genesis_block
  end

  test "top_block" do
    {:ok, seed} = SeedServer.start_link([])
    genesis_block = Block.create_candidate_genesis_block()

    {:ok, node} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

    blockchain = :sys.get_state(node)[:blockchain]
    assert Bitcoin.Blockchain.top_block(blockchain) == genesis_block
  end

  test "send :inv message with one item" do
    {:ok, seed} = SeedServer.start_link([])
    genesis_block = Block.create_candidate_genesis_block()

    {:ok, node} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

    blockchain = :sys.get_state(node)[:blockchain]
    {_n, {g, _,_}} = :sys.get_state(blockchain)

    new_items = %Bitcoin.Schemas.Block{}

    send(blockchain, {:handle_message, :inv, new_items})

    {_n, {g1, _,_}} = :sys.get_state(blockchain)
    assert g1 == [new_items | g]
  end

  test "send :inv message with many items" do
    {:ok, seed} = SeedServer.start_link([])
    genesis_block = Block.create_candidate_genesis_block()

    {:ok, node} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

    blockchain = :sys.get_state(node)[:blockchain]
    {_n, {g, _,_}} = :sys.get_state(blockchain)

    new_items =
      for _n <- 1..10 do
        %Bitcoin.Schemas.Block{}
      end

    send(blockchain, {:handle_message, :inv, new_items})
    {_n, {g1, _,_}} = :sys.get_state(blockchain)
    assert g1 == new_items ++ g
  end

  test "send :getblocks" do
    {:ok, seed} = SeedServer.start_link([])
    genesis_block = Block.create_candidate_genesis_block()

    {:ok, node} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

    blockchain = :sys.get_state(node)[:blockchain]
    heights = [1, 2, 3]

    new_items =
      for i <- 0..2 do
        %Bitcoin.Schemas.Block{
          height: Enum.at(heights, i)
          # hash: Enum.at(hashes, i)
        }
      end

    send(blockchain, {:handle_message, :inv, new_items})

    send(blockchain, {:handle_message, :getblocks, {genesis_block, self()}})

    items =
      receive do
        {:blockchain_handler, :inv, items} -> items
      end

    new_heights = Enum.map(items, fn item -> Map.get(item, :height) end)
    assert heights == new_heights

    send(blockchain, {:handle_message, :getblocks, {Enum.at(new_items, 1), self()}})

    items =
      receive do
        {:blockchain_handler, :inv, items} -> items
      end

    assert new_heights = Enum.map(items, fn item -> Map.get(item, :heights) end)
  end
end
