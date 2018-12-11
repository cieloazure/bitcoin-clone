defmodule Interface.Simulation do
  def scenario1() do
    #alias Bitcoin.Structures.Block
    {:ok, seed} = SeedServer.start_link([])

    wallet = Bitcoin.Wallet.init_wallet()

    recipient = wallet[:address]

    candidate_genesis_block =
      Bitcoin.Structures.Block.create_candidate_genesis_block("1E0FFFFF", recipient)

    mined_genesis_block = Bitcoin.Mining.initiate_mining(candidate_genesis_block)

    Bitcoin.Utilities.EventGenerator.broadcast_event("new_block_found", mined_genesis_block)

    {:ok, genesis_node} =
      Bitcoin.Node.start_link(
        ip_addr: generate_rand_ip_addr(),
        seed: seed,
        genesis_block: mined_genesis_block,
        wallet: wallet
      )

    nodes = for _n <- 1..3 do

      {:ok, node} =
        Bitcoin.Node.start_link(
          ip_addr: generate_rand_ip_addr(),
          seed: seed,
          genesis_block: mined_genesis_block
        )

      Bitcoin.Node.start_mining(node)
      {node, Bitcoin.Node.get_public_address(node)}
    end


    # Distributing money to get them started
    #Enum.each(nodes, fn {_node, address} -> 
    #Bitcoin.Node.transfer_money(genesis_node, List.first(nodes) |> elem(1), 500000, 10)
    #end)
  end

  defp generate_rand_ip_addr() do
    to_string(:rand.uniform(255)) <>
      "." <>
      to_string(:rand.uniform(255)) <>
      "." <> to_string(:rand.uniform(255)) <> "." <> to_string(:rand.uniform(255))
  end
end
