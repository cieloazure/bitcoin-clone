require IEx

defmodule Bitcoin.Node do
  @moduledoc """
  A Bitcoin full node
  """
  use GenServer
  alias Bitcoin.Structures.{Transaction, Block, Chain}
  alias Bitcoin.Utilities.ScriptUtil

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

  def transfer_money(node, recipient, amount, fees \\ 0) do
    GenServer.cast(node, {:transfer_money, recipient, amount, fees})
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

    transaction =
      Bitcoin.Structures.Transaction.create_transaction(
        state[:wallet],
        recipient,
        tx_ins,
        amount,
        fees
      )

    # BROADCAST 
    # add transaction to this node's transaction pool
    state = Keyword.put(state, :tx_pool, [transaction] ++ state[:tx_pool])
    # Broadcast this transaction to other nodes
    Chord.broadcast(state[:chord_api], :new_transaction, transaction)

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

  @impl true
  def handle_info({:new_transaction, transaction}, state) do
    state =
      if verify_transaction(transaction, state),
        do: Keyword.put(state, :tx_pool, [transaction] ++ state[:tx_pool]),
        else: state

    {:noreply, state}
  end

  @impl true
  def handle_info({:orphan_transaction, transaction}, state) do
    state = Keyword.put(state, :orphan_pool, [transaction] ++ state[:tx_pool])
    {:noreply, state}
  end

  ## PRIVATE METHODS ##

  defp verify_transaction(transaction, state) do
    inputs = Map.get(transaction, :inputs)
    outputs = Map.get(transaction, :outputs)

    try do
      # 1. verify structure
      # TODO:

      # 2. verify neither inputs nor outputs are empty
      if Enum.empty?(inputs) or Enum.empty?(outputs),
        do: throw(:break)

      # 3. verify each output (and input) value as well as total is: 0 <= value < 21m
      if !(Transaction.valid?(inputs) and Transaction.valid?(outputs)),
        do: throw(:break)

      # 4. verify standard form of locking and unlocking scripts
      # TODO:

      # 5. verify for each input, referenced output exists.
      # If not, put in orphan pool if matching transaction doesn't already exist.
      # 6. verify for each input, referenced output is unspent
      # 7. verify unlocking script validates against locking scripts.
      if !Enum.all?(inputs, fn input ->
           verify_input(input, transaction, Bitcoin.Blockchain.get_chain(state[:blockchain]))
         end),
         do: throw(:break)

      # 8. reject if sum(outputs) > sum(inputs)
      sum_inputs = Enum.reduce(inputs, fn input, acc -> Map.get(input, :amount) + acc end)
      sum_outputs = Enum.reduce(outputs, fn output, acc -> Map.get(output, :amount) + acc end)

      if sum_outputs > sum_inputs, do: throw(:break)

      # 9. reject if transaction fee is too low to get into empty block
      # TODO:
    catch
      :break -> false
    end
  end

  # TODO: remove transaction as a parameter.
  defp verify_input(input, transaction, chain) do
    try do
      Enum.each(chain, fn block ->
        if Block.contains?(block, input) do
          output =
            Map.get(block, :txns)
            |> Enum.flat_map(fn tx -> Map.get(tx, :outputs) end)
            |> Enum.find(fn txo ->
              Map.get(txo, :tx_id) == Map.get(input, :tx_id) and
                Map.get(txo, :output_index) == Map.get(input, :output_index)
            end)

          if !is_nil(output) do
            # 7. verify unlocking script validates against locking scripts.
            script =
              ScriptUtil.join(Map.get(input, :unlocking_script), Map.get(output, :locking_script))

            if !ScriptUtil.valid?(script),
              do: throw({:break, false})

            # 6. verify for each input, referenced output is unspent
            sub_chain =
              Chain.get_blocks(chain, fn b ->
                Block.get_attr(b, :height) > Block.get_attr(block, :height)
              end)

            if !Transaction.unspent_output?(output, sub_chain),
              do: throw({:break, false})

            throw({:break, true})
          end
        end
      end)

      # 5. verify for each input, referenced output exists.
      # referenced transaction output not found
      # add to orphan pool
      send(self(), {:orphan_transaction, transaction})
      false
    catch
      {:break, result} ->
        result
    end
  end
end
