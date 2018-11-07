defmodule Chord.Node.BlockStorageServer do
  @moduledoc """
  Chord.Node.BlockStorageServer

  This module takes care of storing and retrieving data
  """
  use GenServer
  require Logger

  ###             ###
  ###             ###
  ### Client API  ###
  ###             ###
  ###             ###

  @doc """
  Chord.Node.BlockStorageServer.start_link

  Initiate the block storage server with given options
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Chord.Node.BlockStorageServer.write

  Write the key and data on the store
  """
  def write(store, key, data) do
    GenServer.call(store, {:write, key, data})
  end

  @doc """
  Chord.Node.BlockStorageServer.read

  Read the data in the store corressponding to key
  """
  def read(store, key) do
    GenServer.call(store, {:read, key})
  end

  @doc """
  Chord.Node.BlockStorageServer.delete

  Delete the data in the block storage server corresponding to key
  """
  def delete(store, key) do
    GenServer.call(store, {:delete, key})
  end

  @doc """
  Chord.Node.BlockStorageServer.query

  Get the data from the store satisfying some condition
  """
  def query(store, condition) do
    GenServer.call(store, {:query, condition})
  end

  ###                      ###
  ###                      ###
  ### GenServer Callbacks  ###
  ###                      ###
  ###                      ###

  @doc """
  Chord.Node.BlockStorageServer.init

  Initiates the block storage server with given options and intiates the state. The state of block storage server has
  * node
  * items
  """
  @impl true
  def init(opts) do
    node = Keyword.get(opts, :node)

    # TODO: Initiailize Database, File storage, etc. 
    # Using a map of items with format {key -> value} temporarily
    items = %{}

    {:ok, {node, items}}
  end

  @doc """
  Chord.Node.BlockStorageServer callback for `:write`

  Writes the data in a map corressponding to key
  """
  @impl true
  def handle_call({:write, key, data}, _from, {node, items}) do
    items = Map.put(items, key, data)
    {:reply, :ok, {node, items}}
  end

  @doc """
  Chord.Node.BlockStorageServer callback for `:read`

  Reads the data from the map corressponding to key
  """
  @impl true
  def handle_call({:read, key}, _from, {node, items}) do
    item = Map.get(items, key)
    {:reply, item, {node, items}}
  end

  @doc """
  Chord.Node.BlockStorageServer callback for `:delete`

  Delete the data corressponding to key from the map
  """
  @impl true
  def handle_call({:delete, key}, _from, {node, items}) do
    items = Map.delete(items, key)
    {:reply, :ok, {node, items}}
  end

  @doc """
  Chord.Node.BlockStorageServer callback for `:query`

  Query the map in the store 
  """
  def handle_call({:query, condition}, _from, {node, items}) do
    result_items = Enum.filter(items, condition)
    {:reply, result_items, {node, items}}
  end
end
