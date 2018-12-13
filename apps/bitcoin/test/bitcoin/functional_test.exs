defmodule Bitcoin.FunctionalTest do
  use ExUnit.Case

  #@tag skip: true
  test "functional test for mining competitition between two nodes" do
    alias Bitcoin.Structures.Block
    {:ok, seed} = SeedServer.start_link([])

    wallet = Bitcoin.Wallet.init_wallet()

    recipient = wallet[:address]

    candidate_genesis_block =
      Bitcoin.Structures.Block.create_candidate_genesis_block("1E0FFFFF", recipient)

    mined_genesis_block = Bitcoin.Mining.initiate_mining(candidate_genesis_block)

    Bitcoin.Utilities.EventGenerator.broadcast_event("new_block_found", mined_genesis_block)

    {:ok, node1} =
      Bitcoin.Node.start_link(
        ip_addr: "192.168.0.1",
        seed: seed,
        genesis_block: mined_genesis_block,
        identifier: 1,
        wallet: wallet
      )

    nodes =
      for n <- 2..100 do
        {:ok, node} =
          Bitcoin.Node.start_link(
            ip_addr:
              to_string(:rand.uniform(255)) <>
                "." <>
                to_string(:rand.uniform(255)) <>
                "." <> to_string(:rand.uniform(255)) <> "." <> to_string(:rand.uniform(255)),
            seed: seed,
            genesis_block: mined_genesis_block,
            identifier: n
          )

        Process.sleep(1000)
        node
      end

    
    Process.sleep(5000)

    Enum.each(nodes, fn node ->
      Bitcoin.Node.start_mining(node)
    end)

    Process.sleep(2000)

    addresses =
      Enum.map(nodes, fn node ->
        Bitcoin.Node.get_public_address(node)
      end)

    Enum.each(addresses, fn address ->
      Bitcoin.Node.transfer_money(node1, Enum.at(addresses, 0), 25, 0)
      Process.sleep(30000)
    end)

    Process.sleep(100_000_000)
  end
end
