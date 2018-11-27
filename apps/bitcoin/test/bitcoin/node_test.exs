defmodule Bitcoin.NodeTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Block
  import DummyData

  test "sync operation without any peers will not change the blockchain" do
    {:ok, seed} = SeedServer.start_link([])
    genesis_block = Block.create_candidate_genesis_block()

    {:ok, node} =
      Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

    blockchain = :sys.get_state(node)[:blockchain]
    {_n, {g, _, _}} = :sys.get_state(blockchain)
    Bitcoin.Node.sync(node)
    Process.sleep(1000)
    {_n, {g1, _, _}} = :sys.get_state(blockchain)
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
    {_node, {chain, _, _}} = :sys.get_state(blockchain2)

    assert Bitcoin.Structures.Chain.sort(chain, :height) ==
             Bitcoin.Structures.Chain.sort([genesis_block | new_items], :height)
  end

  test "functional test for mining competitition between two nodes" do
    alias Bitcoin.Structures.Block
    {:ok, seed} = SeedServer.start_link([])

    wallet = Bitcoin.Wallet.init_wallet()

    recipient = wallet[:address]

    candidate_genesis_block =
      Bitcoin.Structures.Block.create_candidate_genesis_block("1EFFFFFF", recipient)

    mined_genesis_block = Bitcoin.Mining.initiate_mining(candidate_genesis_block)

    {:ok, node1} =
      Bitcoin.Node.start_link(
        ip_addr: "192.168.0.1",
        seed: seed,
        genesis_block: mined_genesis_block,
        identifier: 1,
        wallet: wallet
      )

    {:ok, node2} =
      Bitcoin.Node.start_link(
        ip_addr: "192.168.0.2",
        seed: seed,
        genesis_block: mined_genesis_block,
        identifier: 2
      )

    {:ok, node3} =
      Bitcoin.Node.start_link(
        ip_addr: "192.168.0.3",
        seed: seed,
        genesis_block: mined_genesis_block,
        identifier: 3 
      )

    address1 = Bitcoin.Node.get_public_address(node1)
    address2 = Bitcoin.Node.get_public_address(node2)
    Bitcoin.Node.transfer_money(node1, address2, 25, 0)
    Bitcoin.Node.start_mining(node1)
    Bitcoin.Node.start_mining(node2)
    Process.sleep(100000)
  end

  test "update transaction pool" do
    # :debugger.start()
    # :int.ni(Bitcoin.Node)
    # # :int.break(Bitcoin.Node, 191)
    # :int.break(Bitcoin.Node, 198)
    # # :int.ni(Bitcoin.Structures.Transaction)
    # # :int.break(Bitcoin.Structures.Transaction, 215)

    {:ok, seed} = SeedServer.start_link([])
    gen_block = genesis_block()
    chain = get_chain()

    {:ok, node1} =
      Bitcoin.Node.start_link(
        ip_addr: "192.168.0.1",
        seed: seed,
        genesis_block: gen_block,
        identifier: 1
      )

    blockchain1 = :sys.get_state(node1)[:blockchain]

    Bitcoin.Blockchain.set_chain(blockchain1, chain)

    tx_pool = :sys.get_state(node1)[:tx_pool]
    tx = tx5()

    assert Bitcoin.Structures.Transaction.valid?(
             tx,
             chain,
             :sys.get_state(node1)[:tx_pool],
             node1
           )

    send(node1, {:new_transaction, tx})
    Process.sleep(600)
    assert Enum.member?(:sys.get_state(node1)[:tx_pool], tx)
  end
end
