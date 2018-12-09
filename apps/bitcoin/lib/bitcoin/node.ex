defmodule Bitcoin.Node do
  @moduledoc """
  A Bitcoin full node
  """
  use GenServer
  alias Bitcoin.Structures.Transaction
  require Logger

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

  @doc """
  Creates a transaction originating from node's wallet to recipient
  """
  def transfer_money(node, recipient, amount, fees \\ 0) do
    GenServer.cast(node, {:transfer_money, recipient, amount, fees})
  end

  @doc """
  Get the public address of the node's wallet
  """
  def get_public_address(node) do
    GenServer.call(node, {:get_public_address})
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

    wallet = Keyword.get(opts, :wallet) || wallet


    {:ok, blockchain} =
      Bitcoin.Blockchain.start_link(
        genesis_block: genesis_block,
        node: self()
      )

    {:ok, chord_api} =
      Chord.start_link(ip_addr: ip_addr, store: blockchain, seed_server: seed, number_of_bits: 8)

    {:ok,
     [
       ip_addr: ip_addr,
       blockchain: blockchain,
       chord_api: chord_api,
       mining: nil,
       wallet: wallet,
       tx_pool: [],
       orphan_pool: []
     ]}
  end

  @doc """
  Bitcoin.Node.handle_call for `:get_public_address`
  """
  @impl true
  def handle_call({:get_public_address}, _from, state) do
    {:reply, state[:wallet][:address], state}
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

  Bitcoin.Node.handle_cast for `:start_mining`

  This callback will start mining for a new block based on existing chain. It will also 
  terminate any previous mining process and restart a new process based on new updated chain
  """
  @impl true
  def handle_cast({:start_mining, given_chain}, state) do
    # Kill previous mining process
    if !is_nil(state[:mining]) do
      _status = Task.shutdown(state[:mining])
      # IO.inspect(status)
    end

    # Start a new mining process
    chain = given_chain || Bitcoin.Blockchain.get_chain(state[:blockchain])
    # transaction_pool = Bitcoin.Transactions.get_transaction_pool()
    transaction_pool = state[:tx_pool]

    candidate_block =
      Bitcoin.Structures.Block.create_candidate_block(
        transaction_pool,
        chain,
        state[:wallet][:address]
      )

    task = Task.async(Bitcoin.Mining, :mine_async, [candidate_block, self()])
    state = Keyword.put(state, :tx_pool, [])
    state = Keyword.put(state, :mining, task)
    # Bitcoin.Mining.mine_async(candidate_block, self())
    {:noreply, state}
  end

  @doc """
  Bitcoin.Node.handle_cast for ':transfer_money'

  callback to initiate new transaction
  """
  @impl true
  def handle_cast({:transfer_money, recipient, amount, fees}, state) do
    chain = Bitcoin.Blockchain.get_chain(state[:blockchain])

    utxo =
      Bitcoin.Wallet.collect_utxo(
        state[:wallet][:public_key],
        state[:wallet][:private_key],
        chain
      )

    tx_ins = Bitcoin.Structures.Transaction.get_required_inputs(utxo, amount)

    {:ok, transaction} =
      Bitcoin.Structures.Transaction.create_transaction(
        state[:wallet],
        recipient,
        tx_ins,
        amount,
        fees
      )

    IO.puts("Created a new transaction...")
    # BROADCAST 
    # add transaction to this node's transaction pool
    state = Keyword.put(state, :tx_pool, [transaction] ++ state[:tx_pool])
    # Broadcast this transaction to other nodes
    Chord.broadcast(state[:chord_api], :new_transaction, transaction)

    # Broadcast the event to all watching the simulation
    #Bitcoin.Utilities.EventGenerator.broadcast_event("new_transaction", transaction)

    {:noreply, state}
  end

  @doc """
  Callback to handle when a new block is found
  Will broadcast the block to it's peers
  """
  @impl true
  def handle_cast({:new_block_found, new_block}, state) do
    Chord.broadcast(state[:chord_api], :new_block_found, new_block)

    # Broadcast the event to all watching the simulation
    Bitcoin.Utilities.EventGenerator.broadcast_event("new_block_found", new_block)
    
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

  @impl true
  def handle_info({:new_transaction, transaction}, state) do
    IO.puts("Received a transaction.....")
    state =
      if Transaction.valid?(
           transaction,
           Bitcoin.Blockchain.get_chain(state[:blockchain]),
           state[:tx_pool],
           self()
         ) do
        state = Keyword.put(state, :tx_pool, [transaction] ++ state[:tx_pool])

        {orphan_pool, accepted_txns} =
          update_orphan_pool(transaction, state[:orphan_pool])

        state = Keyword.put(state, :orphan_pool, orphan_pool)
        Keyword.put(state, :tx_pool, accepted_txns ++ state[:tx_pool])
      else
        state
      end

    {:noreply, state}
  end

  @impl true
  def handle_info({:orphan_transaction, transaction, unreferenced_inputs}, state) do
    state =
      if !Enum.any?(state[:orphan_pool], fn {txn, _unref_o} -> Map.equal?(txn, transaction) end),
        do:
          Keyword.put(
            state,
            :orphan_pool,
            [{transaction, unreferenced_inputs}] ++ state[:orphan_pool]
          ),
        else: state

    {:noreply, state}
  end

  @doc """
  Handling messages from the tasks
  """
  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  ## PRIVATE METHODS ##
  defp update_orphan_pool(transaction, orphan_pool) do
    transaction_params =
      Map.get(transaction, :outputs)
      |> Enum.map(fn output -> {Map.get(output, :tx_id), Map.get(output, :output_index)} end)

    adopted =
      Enum.filter(orphan_pool, fn {_orphan, unreferenced_inputs} ->
        unreferenced_inputs
        |> Enum.all?(fn input ->
          Enum.any?(transaction_params, fn {tx_id, output_index} ->
            Map.get(input, :tx_id) == tx_id and Map.get(input, :output_index) == output_index
          end)
        end)
      end)

    accepted_txns =
      if !is_nil(adopted) do
        Enum.filter(orphan_pool, fn {orphan, _unreferenced_input} ->
          Enum.any?(adopted, fn {tx, _unref_input} -> Map.equal?(tx, orphan) end)
        end)
      else
        orphan_pool
      end
    
    orphan_pool = orphan_pool -- accepted_txns

    {accepted_txns, _referenced_inputs} = Enum.unzip(accepted_txns)
    
    {orphan_pool, accepted_txns}
  end
end
