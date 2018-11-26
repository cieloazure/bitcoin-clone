require IEx

defmodule Bitcoin.BlockchainTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Block
  import Bitcoin.Utilities.Crypto

  describe "start_link" do
    test "initialize the blockchain with genesis block" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]
      {n, {g, _, _}} = :sys.get_state(blockchain)
      assert node == n
      assert List.first(g) == genesis_block
    end
  end

  describe "top_block" do
    test "get the topmost block in blockchain" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]
      assert Bitcoin.Blockchain.top_block(blockchain) == genesis_block
    end
  end

  describe "get_chain" do
    test "gets the entire blockchain" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]
      assert Bitcoin.Blockchain.get_chain(blockchain) == [genesis_block]
    end
  end

  describe "handle_message for :inv" do
    test "send :inv message with one item" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]
      {_n, {g, _, _}} = :sys.get_state(blockchain)

      new_items = %Bitcoin.Schemas.Block{}

      send(blockchain, {:handle_message, :inv, new_items})

      {_n, {g1, _, _}} = :sys.get_state(blockchain)
      assert g1 == [new_items | g]
    end

    test "send :inv message with many items" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]
      {_n, {g, _, _}} = :sys.get_state(blockchain)

      new_items =
        for _n <- 1..10 do
          %Bitcoin.Schemas.Block{}
        end

      send(blockchain, {:handle_message, :inv, new_items})
      {_n, {g1, _, _}} = :sys.get_state(blockchain)
      assert g1 == new_items ++ g
    end
  end

  describe "handle_message for :getblocks" do
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

  describe "handle_message for :new_block_found with invalid block" do
    test "when the block is invalid it should return the same chain again" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]

      {_, {chain_before, _, _}} = :sys.get_state(blockchain)
      genesis_block = Bitcoin.Structures.Block.create_candidate_genesis_block("1EFFFFFF")
      send(blockchain, {:handle_message, :new_block_found, genesis_block})
      {_, {chain_after, _, _}} = :sys.get_state(blockchain)
      assert chain_before == chain_after
    end
  end

  describe "handle_message for :new_block_found with valid block" do
    test "the new block belongs in the chain at the top" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()
      genesis_block = Bitcoin.Mining.initiate_mining(genesis_block)

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]

      {_, {chain_before, _, _}} = :sys.get_state(blockchain)
      block1 = Bitcoin.Structures.Block.create_candidate_block([], chain_before)
      mined_block = Bitcoin.Mining.initiate_mining(block1)
      send(blockchain, {:handle_message, :new_block_found, mined_block})
      Process.sleep(1000)
      {_, {chain_after, _, _}} = :sys.get_state(blockchain)
      assert length(chain_after) > length(chain_before)
    end

    test "the new block belongs in the chain not at the top hence a fork is needed" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()
      genesis_block = Bitcoin.Mining.initiate_mining(genesis_block)

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]

      chain = create_chain([], 6, nil, 0)
      Bitcoin.Blockchain.set_chain(blockchain, chain)
      {_, {chain_before, forks_before, _}} = :sys.get_state(blockchain)
      assert length(forks_before) == 0
      redundant_chain = Enum.reverse(chain_before) |> Enum.take(4)
      block1 = Bitcoin.Structures.Block.create_candidate_block([], redundant_chain)
      mined_block1 = Bitcoin.Mining.initiate_mining(block1)
      send(blockchain, {:handle_message, :new_block_found, mined_block1})
      {_, {chain_after, forks_after, _}} = :sys.get_state(blockchain)
      assert length(forks_after) != 0
      assert length(chain_after) < length(chain_before)
    end

    test "the new block belongs in one of the forks, hence extending the fork, the forks are not of equal length, hence confirming the main chain by using the extended fork" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()
      genesis_block = Bitcoin.Mining.initiate_mining(genesis_block)

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]

      chain = create_chain([], 6, nil, 0)
      Bitcoin.Blockchain.set_chain(blockchain, chain)
      {_, {chain_before, forks_before, _}} = :sys.get_state(blockchain)
      assert length(forks_before) == 0
      redundant_chain = Enum.reverse(chain_before) |> Enum.take(4)
      block1 = Bitcoin.Structures.Block.create_candidate_block([], redundant_chain)
      mined_block1 = Bitcoin.Mining.initiate_mining(block1)
      send(blockchain, {:handle_message, :new_block_found, mined_block1})
      {_, {chain_after, forks_after, _}} = :sys.get_state(blockchain)
      assert length(forks_after) != 0
      assert length(chain_after) < length(chain_before)

      new_redundant_chain = [block1 | redundant_chain]
      block2 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      mined_block2 = Bitcoin.Mining.initiate_mining(block2)
      IO.inspect(mined_block2)
      send(blockchain, {:handle_message, :new_block_found, mined_block2})
      {_, {chain_after_2, forks_after_2, _}} = :sys.get_state(blockchain)
      assert length(chain_after_2) > length(chain_before)
      assert length(forks_after_2) == 0
    end

    test "the new block belongs in one of the forks, hence extending the fork, the forks are of equal length, hence main chain will not be extended however forks will be extended" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()
      genesis_block = Bitcoin.Mining.initiate_mining(genesis_block)

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]

      chain = create_chain([], 6, nil, 0)
      Bitcoin.Blockchain.set_chain(blockchain, chain)
      {_, {chain_before, forks_before, _}} = :sys.get_state(blockchain)

      redundant_chain = Enum.reverse(chain_before) |> Enum.take(4)
      block1 = Bitcoin.Structures.Block.create_candidate_block([], redundant_chain)
      mined_block1 = Bitcoin.Mining.initiate_mining(block1)
      send(blockchain, {:handle_message, :new_block_found, mined_block1})
      {_, {chain_after_1, forks_after_1, _}} = :sys.get_state(blockchain)

      new_redundant_chain = [mined_block1 | redundant_chain]
      block2 = Bitcoin.Structures.Block.create_candidate_block([], new_redundant_chain)
      mined_block2 = Bitcoin.Mining.initiate_mining(block2)

      send(blockchain, {:handle_message, :new_block_found, mined_block2})
      {_, {chain_after_2, forks_after_2, _}} = :sys.get_state(blockchain)
      assert length(chain_after_1) == length(chain_after_2)
    end

    test "the new block is an orphan" do
      {:ok, seed} = SeedServer.start_link([])
      genesis_block = Block.create_candidate_genesis_block()
      genesis_block = Bitcoin.Mining.initiate_mining(genesis_block)

      {:ok, node} =
        Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed, genesis_block: genesis_block)

      blockchain = :sys.get_state(node)[:blockchain]

      chain = create_chain([], 6, nil, 0)
      Bitcoin.Blockchain.set_chain(blockchain, Enum.reverse(chain) |> Enum.take(4))
      {_, {chain_before, forks_before, orphan_before}} = :sys.get_state(blockchain)
      assert length(orphan_before) == 0

      block1 = Bitcoin.Structures.Block.create_candidate_block([], chain)
      mined_block1 = Bitcoin.Mining.initiate_mining(block1)
      send(blockchain, {:handle_message, :new_block_found, mined_block1})
      {_, {chain_after, forks_after, orphan_after}} = :sys.get_state(blockchain)
      assert length(orphan_after) != 0
    end

    test "the new block is the parent of one of the orphan block and is in the main chain" do
    end

    test "the new block is the parent of one of the orphan and is in one of the forks"
  end

  defp create_chain(chain, length, _, index) when index >= length do
    chain
  end

  defp create_chain(chain, length, last_block_header, index) do
    prev_block = last_block_header || <<0>>

    blockh = %Bitcoin.Schemas.BlockHeader{
      prev_block_hash: double_sha256(prev_block)
    }

    block = %Bitcoin.Schemas.Block{
      block_header: blockh,
      height: index
    }

    chain = [block | chain]
    create_chain(chain, length, blockh, index + 1)
  end
end
