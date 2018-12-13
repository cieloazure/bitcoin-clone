defmodule Bitcoin.FunctionalTest do
  use ExUnit.Case

  # @tag skip: true
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
      for n <- 2..10 do
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

    # Process.sleep(5_000)
    Enum.each(nodes, fn node ->
      Bitcoin.Node.start_mining(node)
    end)

    Process.sleep(2000)

    addresses =
      Enum.map(nodes, fn node ->
        Bitcoin.Node.get_public_address(node)
      end)


    Enum.zip(nodes, addresses)
    |>  Enum.each(fn {node, address} ->
       Bitcoin.Node.transfer_money(node1, address , 250000, 0)
       Bitcoin.Node.transfer_money(node, Enum.random(addresses), 12500, 0)
       Process.sleep(10000)
     end)

    Process.sleep(100000000000)
  end

  def send_money(nodes, addresses) do
    IO.inspect("in send money")
    for _i <- 1..10 do
      node = Enum.random(nodes)
      balance = Bitcoin.Node.get_balance(node)

      Bitcoin.Node.transfer_money(node, Enum.random(addresses), 0.10 * balance, 0)
    end
    send_money(nodes, addresses)
  end
end


