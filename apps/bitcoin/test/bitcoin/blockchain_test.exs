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
    {n, g} = :sys.get_state(blockchain)
    assert Bitcoin.Blockchain.get_top_hash(blockchain) == genesis_block()
  end

  test "send :inv message with one item" do
    {:ok, seed} = SeedServer.start_link([])
    {:ok, node} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
    blockchain = :sys.get_state(node)[:blockchain]
    {n, g} = :sys.get_state(blockchain)

    new_items = %Bitcoin.Schemas.Block{}

    send(blockchain, {:handle_message, :inv, new_items})

    {n, g1} = :sys.get_state(blockchain)
    assert g1 == [new_items | g]
  end

  test "send :inv message with many items" do
    {:ok, seed} = SeedServer.start_link([])
    {:ok, node} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
    blockchain = :sys.get_state(node)[:blockchain]
    {n, g} = :sys.get_state(blockchain)

    new_items =
      for _n <- 1..10 do
        %Bitcoin.Schemas.Block{}
      end

    send(blockchain, {:handle_message, :inv, new_items})
    {n, g1} = :sys.get_state(blockchain)
    assert g1 == new_items ++ g
  end

  defp genesis_block do
    genesis_transaction = %Bitcoin.Schemas.Transaction{}

    %Bitcoin.Schemas.Block{
      block_index: 0,
      block_size: 10,
      tx_counter: 1,
      txs: [genesis_transaction]
    }
  end
end
