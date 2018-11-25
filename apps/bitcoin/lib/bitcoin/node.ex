defmodule Bitcoin.Node do
  @moduledoc """
  A Bitcoin full node
  """
  use GenServer

  ###             ###
  ###             ###
  ### Client API  ###
  ###             ###
  ###             ###

  @doc """
  Bitcoin.Node.start_link

  Starts a bitcoin full node
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Bitcoin.Node.sync

  Sync blocks with peers
  """
  def sync(node) do
    GenServer.cast(node, {:sync})
  end

  def new_block_found(node, new_block) do
    GenServer.cast(node, {:new_block_found, new_block})
  end

  @doc """
  Bitcoin.Node.start_mining
  """
  def start_mining(node, chain \\ nil) do
    GenServer.cast(node, {:start_mining, chain})
  end

  ###                      ###
  ###                      ###
  ### GenServer Callbacks  ###
  ###                      ###
  ###                      ###

  @doc """
  Bitcoin.Node.init

  Initialize with ip_addr and seed process
  The State of the node contains - 
  1. Ip address
  2. Seed node(s)
  3. Blockchain handler
  4. Chord peer to peer network
  5. Wallet
  """
  @impl true
  def init(opts) do
    ip_addr = Keyword.get(opts, :ip_addr)
    seed = Keyword.get(opts, :seed)
    genesis_block = Keyword.get(opts, :genesis_block)
    wallet = Bitcoin.Wallet.init_wallet()

    {:ok, blockchain} =
      Bitcoin.Blockchain.start_link(
        genesis_block: genesis_block,
        node: self()
      )

    {:ok, chord_api} =
      Chord.start_link(ip_addr: ip_addr, store: blockchain, seed_server: seed, number_of_bits: 8)

    {:ok,
     [ip_addr: ip_addr, blockchain: blockchain, chord_api: chord_api, mining: nil, wallet: wallet]}
  end

  @doc """
  Bitcoin.Node.handle_cast for `:sync`

  callback to handle sync of peers
  """
  @impl true
  def handle_cast({:sync}, state) do
    top_hash = Bitcoin.Blockchain.top_block(state[:blockchain])
    Chord.send_peers(state[:chord_api], :getblocks, {top_hash, self()})
    {:noreply, state}
  end

  @doc """
  """
  @impl true
  def handle_cast({:start_mining, given_chain}, state) do
    # Kill previous mining process
    if !is_nil(state[:mining]) do
      Process.exit(state[:mining], :kill)
    end

    # Start a new mining process
    chain = given_chain || Bitcoin.Blockchain.get_chain(state[:blockchain])
    # transaction_pool = Bitcoin.Transactions.get_transaction_pool()
    transaction_pool = []

    candidate_block =
      Bitcoin.Structures.Block.create_candidate_block(
        transaction_pool,
        chain,
        state[:wallet][:bitcoin_address]
      )

    {:ok, pid} = Task.start(Bitcoin.Mining, :mine_async, [candidate_block, self()])
    state = Keyword.put(state, :mining, pid)
    # Bitcoin.Mining.mine_async(candidate_block, self())
    {:noreply, state}
  end

  @doc """
  Callback to handle when a new block is found
  """
  @impl true
  def handle_cast({:new_block_found, new_block}, state) do
    Chord.broadcast(state[:chord_api], :new_block_found, new_block)
    {:noreply, state}
  end

  @doc """
  Bitcoin.Node.handle_cast for `:blockchain_handler`

  Callback to delegate the tasks to blockchain
  """
  @impl true
  def handle_info({:blockchain_handler, message, payload}, state) do
    send(state[:blockchain], {:handle_message, message, payload})
    {:noreply, state}
  end
end
