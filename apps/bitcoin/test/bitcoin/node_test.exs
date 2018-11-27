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

  test "broadcast" do
    alias Bitcoin.Structures.Block
    {:ok, seed} = SeedServer.start_link([])

    candidate_genesis_block =
      Bitcoin.Structures.Block.create_candidate_genesis_block("1effffff", "1akashbharatshingte")

    mined_genesis_block = Bitcoin.Mining.initiate_mining(candidate_genesis_block)

    {:ok, node1} =
      Bitcoin.Node.start_link(
        ip_addr: "192.168.0.1",
        seed: seed,
        genesis_block: mined_genesis_block,
        identifier: 1
      )

    IO.inspect(node1)

    Bitcoin.Node.start_mining(node1)

    # alias Bitcoin.Structures.Block
    # {:ok, seed} = SeedServer.start_link([])

    # candidate_genesis_block =
    # Bitcoin.Structures.Block.create_candidate_genesis_block("1EFFFFFF", "1akashbharatshingte")

    # mined_genesis_block = Bitcoin.Mining.initiate_mining(candidate_genesis_block)

    # {:ok, node1} =
    # Bitcoin.Node.start_link(
    # ip_addr: "192.168.0.1",
    # seed: seed,
    # genesis_block: mined_genesis_block,
    # identifier: 1
    # )

    # {:ok, node2} =
    # Bitcoin.Node.start_link(
    # ip_addr: "192.168.0.2",
    # seed: seed,
    # genesis_block: mined_genesis_block,
    # identifier: 2
    # )
    # Bitcoin.Node.start_mining(node1)

    # Process.sleep(1000)

    # {:ok, node2} =
    # Bitcoin.Node.start_link(
    # ip_addr: "192.168.0.2",
    # seed: seed,
    # genesis_block: genesis_block,
    # identifier: 2
    # )
    # Process.sleep(3000)
    ## Bitcoin.Node.new_block_found(node1, "<new-block-to-broadcast>")
    # Process.sleep(5000)
  end

  test "update transaction pool. valid transaction" do

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
    # Process.sleep(600)
    assert Enum.member?(:sys.get_state(node1)[:tx_pool], tx)
  end

  test "don't update transaction pool. invalid transaction" do

    {:ok, seed} = SeedServer.start_link([])
    gen_block = genesis_block()
    chain = [gen_block]

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
    tx = inv_tx1()

    assert !Bitcoin.Structures.Transaction.valid?(
             tx,
             chain,
             :sys.get_state(node1)[:tx_pool],
             node1
           )

    send(node1, {:new_transaction, tx})
    assert !Enum.member?(:sys.get_state(node1)[:tx_pool], tx)
  end

  test "add transaction to orphan pool if referenced_output doesn't exist in chain" do
    {:ok, seed} = SeedServer.start_link([])
    gen_block = genesis_block()
    chain = get_chain

    {:ok, node1} =
      Bitcoin.Node.start_link(
        ip_addr: "192.168.0.1",
        seed: seed,
        genesis_block: gen_block,
        identifier: 1
      )

    blockchain1 = :sys.get_state(node1)[:blockchain]
    Bitcoin.Blockchain.set_chain(blockchain1, chain)

    send(node1, {:new_transaction, orphan_tx1()})

    # Process.sleep(600_000)
    assert !Enum.member?(:sys.get_state(node1)[:tx_pool], orphan_tx1())

    assert Enum.any?(:sys.get_state(node1)[:orphan_pool], fn {tx, _input} ->
             Map.equal?(tx, orphan_tx1())
           end)
  end

  test "update orphan and transaction pool on receiving a new transaction with referenced_output" do


    {:ok, seed} = SeedServer.start_link([])
    gen_block = genesis_block()
    chain = get_chain

    {:ok, node1} =
      Bitcoin.Node.start_link(
        ip_addr: "192.168.0.1",
        seed: seed,
        genesis_block: gen_block,
        identifier: 1
      )

    blockchain1 = :sys.get_state(node1)[:blockchain]
    Bitcoin.Blockchain.set_chain(blockchain1, chain)

    send(node1, {:new_transaction, orphan_tx1()})
      Process.sleep(100)
    send(node1, {:new_transaction, tx5()})
    state = :sys.get_state(node1)

    assert Enum.member?(:sys.get_state(node1)[:tx_pool], orphan_tx1())
    assert Enum.member?(:sys.get_state(node1)[:tx_pool], tx5())

    assert !Enum.any?(:sys.get_state(node1)[:orphan_pool], fn {tx, _input} ->
             Map.equal?(tx, orphan_tx1())
           end)
  end
end
