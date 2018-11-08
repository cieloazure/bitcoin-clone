defmodule Bitcoin.BlockchainTest do
  use ExUnit.Case

  test "initialize the blockchain with genesis block" do
    {:ok, seed} = SeedServer.start_link([])
    {:ok, node} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
    blockchain = :sys.get_state(node)[:blockchain]
    {n, g} = :sys.get_state(blockchain)
    assert node == n
    assert List.first(g) == genesis_block()
  end

  test "get_top_hash" do
    {:ok, seed} = SeedServer.start_link([])
    {:ok, node} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
    blockchain = :sys.get_state(node)[:blockchain]
    assert Bitcoin.Blockchain.get_top_hash(blockchain) == genesis_block()
  end

  test "send :inv message with one item" do
    {:ok, seed} = SeedServer.start_link([])
    {:ok, node} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
    blockchain = :sys.get_state(node)[:blockchain]
    {_n, g} = :sys.get_state(blockchain)

    new_items = %Bitcoin.Schemas.Block{}

    send(blockchain, {:handle_message, :inv, new_items})

    {_n, g1} = :sys.get_state(blockchain)
    assert g1 == [new_items | g]
  end

  test "send :inv message with many items" do
    {:ok, seed} = SeedServer.start_link([])
    {:ok, node} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
    blockchain = :sys.get_state(node)[:blockchain]
    {_n, g} = :sys.get_state(blockchain)

    new_items =
      for _n <- 1..10 do
        %Bitcoin.Schemas.Block{}
      end

    send(blockchain, {:handle_message, :inv, new_items})
    {_n, g1} = :sys.get_state(blockchain)
    assert g1 == new_items ++ g
  end

  test "send :getblocks" do
    {:ok, seed} = SeedServer.start_link([])
    {:ok, node} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
    blockchain = :sys.get_state(node)[:blockchain]
    hashes = ["1234", "5678", "2343"]
    heights = [1, 2, 3]

    new_items =
      for i <- 0..2 do
        %Bitcoin.Schemas.Block{height: Enum.at(heights, i), hash: Enum.at(hashes, i)}
      end

    send(blockchain, {:handle_message, :inv, new_items})

    send(blockchain, {:handle_message, :getblocks, {"0000", self()}})

    items =
      receive do
        {:blockchain_handler, :inv, items} -> items
      end

    new_hashes = Enum.map(items, fn item -> Map.get(item, :hash) end)
    assert new_hashes == hashes

    send(blockchain, {:handle_message, :getblocks, {"1234", self()}})

    items =
      receive do
        {:blockchain_handler, :inv, items} -> items
      end

    new_hashes = Enum.map(items, fn item -> Map.get(item, :hash) end)
    assert new_hashes == Enum.take(hashes, -2)
  end

  defp genesis_block do
    genesis_transaction = %Bitcoin.Schemas.Transaction{}

    %Bitcoin.Schemas.Block{
      block_index: 0,
      block_size: 10,
      tx_counter: 1,
      txs: [genesis_transaction],
      height: 0,
      hash: "0000"
    }
  end
end
