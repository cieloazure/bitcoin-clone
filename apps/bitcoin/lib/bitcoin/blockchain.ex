defmodule Bitcoin.Blockchain do
  @moduledoc """
  Bitcoin.Blockchain

  This module will maintain a blockchain and manage blockchain specific processes. 
  """
  use GenServer
  require Logger

  alias Bitcoin.Structures.{Chain, Block}

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

    {:ok, {node, chain}}
  end

  @impl true
  def handle_call({:top_block}, _from, {_node, chain} = state) do
    {:reply, Chain.top(chain), state}
  end

  @doc """
  Bitcoin.Blockchain.handle_info callback for `:handle_message`

  An important callback to manage messages of the blockchain and decide to do further processing
  """
  @impl true
  def handle_info({:handle_message, message, payload}, {node, chain}) do
    chain =
      case message do
        :getblocks ->
          {top_hash, to} = payload
          send_inventory(chain, top_hash, to)
          chain

        :inv ->
          blocks = payload
          save_inventory(chain, blocks)

        :new_block_found ->
          new_block_found(payload, node)
          chain
          # save_block
          # block = payload
          # save_inventory(chain, block)

        :new_transaction ->
          # save_transaction
          # broadcast_transaction
          nil
      end

    {:noreply, {node, chain}}
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


  defp new_block_found(payload, node) do
    IO.puts("here  at the store of #{inspect(:sys.get_state(node)[:ip_addr])}")
  end
end
