defmodule Bitcoin.Blockchain do
  @moduledoc """
  Bitcoin.Blockchain

  This module will maintain a blockchain and manage blockchain specific processes. 
  """
  use GenServer
  require Logger

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
  Bitcoin.Blockchain.get_top_hash

  Get the topmost hash in the blockchain
  """
  def get_top_hash(node) do
    GenServer.call(node, {:get_top_hash})
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

    # TODO: Initiailize Database, File storage, etc. 
    # Using a map of items with format {key -> value} temporarily
    # list of blocks
    # store = DB.initialize()
    store = []
    store = if !is_nil(genesis_block), do: [genesis_block | store]

    {:ok, {node, store}}
  end

  @doc """
  Bitcoin.Blockchain.handle_call callback for `:get_top_hash`

  Get the topmost hash
  """
  @impl true
  def handle_call({:get_top_hash}, _from, {node, store}) do
    {:reply, List.last(store), {node, store}}
  end

  @doc """
  Bitcoin.Blockchain.handle_info callback for `:handle_message`

  An important callback to manage messages of the blockchain and decide to do further processing
  """
  @impl true
  def handle_info({:handle_message, message, payload}, {node, store}) do
    store =
      case message do
        :getblocks ->
          {top_hash, to} = payload
          send_inventory(store, top_hash, to)
          store

        :inv ->
          blocks = payload
          save_inventory(store, blocks)

        :new_block ->
          nil

        :new_transaction ->
          nil
      end

    {:noreply, {node, store}}
  end

  #### PRIVATE FUNCTIONS #####

  # send_inventory
  # Arguments: 
  #    * store -> list of items
  #    * top_hash -> the hash present with the node     
  #    * node -> the ip_addr(here `pid`) of the node
  defp send_inventory(store, top_hash, node) do
    # Query
    #
    # Find items after the top_hash
    items = Enum.sort(store, fn op1, op2 -> Map.get(op1, :height) <= Map.get(op2, :height) end)
    index = Enum.find_index(items, fn item -> Map.get(item, :hash) == top_hash end)
    new_items = Enum.take(items, -(length(items) - (index + 1)))

    # Send those items  to the node using :inv message
    # Send to the blockchain process of the node
    send(node, {:blockchain_handler, :inv, new_items})
  end

  # save_inventory
  # Arguments:
  #   * store -> list of items
  #   * blocks -> new blocks to be save in the blockchain
  defp save_inventory(store, blocks) do
    # DBs operations
    if is_list(blocks) do
      blocks ++ store
    else
      [blocks | store]
    end
  end
end
