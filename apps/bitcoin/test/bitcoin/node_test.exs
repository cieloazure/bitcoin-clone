defmodule Bitcoin.NodeTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Block

  test "sync operation without any peers will not change the blockchain" do
    {:ok, seed} = SeedServer.start_link([])
    genesis_block = Block.create_candidate_genesis_block()

    {:ok, node} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

    blockchain = :sys.get_state(node)[:blockchain]
    {_n, g} = :sys.get_state(blockchain)
    Bitcoin.Node.sync(node)
    Process.sleep(1000)
    {_n, g1} = :sys.get_state(blockchain)
    assert g == g1
  end

  test "sync operation with one  peers will change the blockchain" do
    {:ok, seed} = SeedServer.start_link([])
    genesis_block = Block.create_candidate_genesis_block()

    {:ok, node1} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

    blockchain1 = :sys.get_state(node1)[:blockchain]

    heights = [1, 2, 3]

    new_items =
      for i <- 0..2 do
        %Bitcoin.Schemas.Block{
          height: Enum.at(heights, i)
        }
      end

    send(blockchain1, {:handle_message, :inv, new_items})

    Process.sleep(1000)

    {:ok, node2} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.2", seed: seed, genesis_block: genesis_block)

    Process.sleep(1000)
    Bitcoin.Node.sync(node2)
    Process.sleep(1000)
    blockchain2 = :sys.get_state(node2)[:blockchain]
    {_node, chain} = :sys.get_state(blockchain2)

    assert Bitcoin.Structures.Chain.sort(chain, :height) ==
             Bitcoin.Structures.Chain.sort([genesis_block | new_items], :height)
  end
end
