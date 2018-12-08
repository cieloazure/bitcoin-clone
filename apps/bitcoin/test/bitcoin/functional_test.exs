defmodule Bitcoin.FunctionalTest do
  use ExUnit.Case

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

    Bitcoin.Node.start_mining(node1)
    Bitcoin.Node.start_mining(node2)
    Bitcoin.Node.start_mining(node3)

    address1 = Bitcoin.Node.get_public_address(node1)
    address2 = Bitcoin.Node.get_public_address(node2)
    address3 = Bitcoin.Node.get_public_address(node3)

    Bitcoin.Node.transfer_money(node1, address2, 25, 0)
    Process.sleep(2000)

    Bitcoin.Node.transfer_money(node2, address1, 12.5, 0)
    Process.sleep(2000)

    Bitcoin.Node.transfer_money(node1, address3, 2500, 0)
    Process.sleep(10000)
  end
end
