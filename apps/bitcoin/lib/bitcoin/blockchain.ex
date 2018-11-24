require IEx

defmodule Bitcoin.Blockchain do
  @moduledoc """
  Bitcoin.Blockchain

  This module will maintain a blockchain and manage blockchain specific processes. 
  """
  use GenServer
  require Logger

  alias Bitcoin.Structures.{Chain, Block}
  import Bitcoin.Utilities.Crypto

  ###             ###
  ###             ###
  ### Client API  ###
  ###             ###
  ###             ###

  @doc """
  Bitcoin.Blockchain.start_link

  Initiate the block storage server with given options
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Get the topmost block of the chain
  """
  def top_block(blockchain) do
    GenServer.call(blockchain, {:top_block})
  end

  @doc """
  Get the chain
  """
  def get_chain(blockchain) do
    GenServer.call(blockchain, {:get_chain})
  end

  ###                      ###
  ###                      ###
  ### GenServer Callbacks  ###
  ###                      ###
  ###                      ###

  @doc """
  Bitcoin.Blockchain.init

  Intialize the process with a node and genesis_block
  """
  @impl true
  def init(opts) do
    node = Keyword.get(opts, :node)
    genesis_block = Keyword.get(opts, :genesis_block)
    chain = Chain.new_chain(genesis_block)
    forks = []
    orphans = []

    {:ok, {node, {chain, forks, orphans}}}
  end

  @impl true
  def handle_call({:top_block}, _from, {_node, {chain, _forks, _orphans}} = state) do
    {:reply, Chain.top(chain), state}
  end

  @impl true
  def handle_call({:get_chain}, _from, {_node, {chain, _forks, _orphans}} = state) do
    {:reply, chain, state}
  end

  @doc """
  Bitcoin.Blockchain.handle_info callback for `:handle_message`

  An important callback to manage messages of the blockchain and decide to do further processing
  """
  @impl true
  def handle_info({:handle_message, message, payload}, {node, {chain, forks, orphans}}) do
    {chain, forks, orphans} =
      case message do
        :getblocks ->
          {top_hash, to} = payload
          send_inventory(chain, top_hash, to)
          {chain, forks, orphans}

        :inv ->
          blocks = payload
          new_chain = save_inventory(chain, blocks)
          {new_chain, forks, orphans}

        :new_block_found ->
          {new_chain, new_forks, new_orphans} =
            new_block_found(payload, node, {chain, forks, orphans})

          IEx.pry()
          Bitcoin.Node.start_mining(node, new_chain)
          {new_chain, new_forks, new_orphans}

        :new_transaction ->
          # save_transaction
          # broadcast_transaction
          nil
      end

    {:noreply, {node, {chain, forks, orphans}}}
  end

  #### PRIVATE FUNCTIONS #####

  # send_inventory
  # Arguments: 
  #    * chain -> list of items
  #    * top_hash -> the hash present with the node     
  #    * node -> the ip_addr(here `pid`) of the node
  defp send_inventory(chain, top_block, node) do
    block = Chain.get_blocks(chain, fn block -> block == top_block end)
    height = Block.get_attr(List.first(block), :height)

    new_blocks =
      if !is_nil(height) do
        Chain.get_blocks(chain, fn block ->
          Block.get_attr(block, :height) > height
        end)
      else
        Chain.get_blocks(chain)
      end

    send(node, {:blockchain_handler, :inv, new_blocks})
  end

  # save_inventory
  # Arguments:
  #   * chain -> list of items
  #   * blocks -> new blocks to be save in the blockchain
  defp save_inventory(chain, blocks) do
    # DBs operations
    Chain.save(chain, blocks)
  end

  defp new_block_found(payload, node, {chain, forks, orphans}) do
    IO.puts("here  at the store of #{inspect(:sys.get_state(node)[:ip_addr])}")
    new_block = payload
    {location, condition} = find_block(new_block, {chain, forks})
    IEx.pry()

    case {location, condition} do
      {:in_chain, :at_top} ->
        new_chain = [new_block | chain]
        {new_chain, orphans} = consolidate_orphans(new_chain, orphans)
        {new_chain, forks, orphans}

      {:in_chain, :with_fork} ->
        {chain, forks} = Chain.fork(chain, new_block)
        {forks, orphans} = consolidate_orphans_in_forks(forks, orphans)
        {chain, forks, orphans}

      {:in_fork, fork_index} ->
        fork = Enum.at(forks, fork_index)
        extended_fork = [new_block | fork]
        new_chain = extended_fork
        {new_chain, orphans} = consolidate_orphans(new_chain, orphans)
        {new_chain, [], orphans}

      {:in_orphan} ->
        {chain, forks, [new_block | orphans]}
    end
  end

  defp find_block(block, {chain, forks}) do
    prev_hash = Block.get_header_attr(block, :prev_block_hash)

    block =
      Enum.find(chain, fn block ->
        prev_hash == Block.get_attr(block, :block_header) |> double_sha256
      end)

    if !is_nil(block) do
      top = Chain.top(chain)
      top_hash = Block.get_attr(top, :block_header) |> double_sha256

      if prev_hash == top_hash do
        {:in_chain, :at_top}
      else
        {:in_chain, :with_fork}
      end
    else
      fork_index =
        Enum.find_index(forks, fn fork ->
          block =
            Enum.find(fork, fn block ->
              prev_hash == Block.get_attr(block, :block_header) |> double_sha256
            end)

          !is_nil(block)
        end)

      if !is_nil(fork_index) do
        {:in_fork, fork_index}
      else
        {:in_orphan}
      end
    end
  end

  defp consolidate_orphans_in_forks(forks, orphans) do
    Enum.map_reduce(forks, orphans, fn fork_list, orphans ->
      consolidate_orphans(fork_list, orphans)
    end)
  end

  defp consolidate_orphans(chain, orphans) do
    # any of the orphans
    {no_more_orphans, still_orphans} =
      Enum.split_with(orphans, fn orphan ->
        prev_hash = Block.get_header_attr(orphan, :prev_block_hash)
        ## TODO: prev block find can be refactored into a separate function
        # It is being repeated a lot
        block =
          Enum.find(chain, fn block ->
            prev_hash == Block.get_attr(block, :block_header) |> double_sha256
          end)

        !is_nil(block)
      end)

    {chain ++ no_more_orphans, still_orphans}
  end
end
