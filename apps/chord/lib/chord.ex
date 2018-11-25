defmodule Chord do
  @moduledoc """
  Chord

  The api methods to be exposed. includes important methods like insert and lookup data in the entire chord network.
  """
  use GenServer
  require Logger

  ###             ###
  ###             ###
  ### Client API  ###
  ###             ###
  ###             ###

  @doc """
  Chord.start_link

  Starts the genserver with given opts which include the ip address to start the node with
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Chord.insert 

  Inserts the data in the chord network
  """
  def insert(api, data, identifier \\ nil) do
    GenServer.call(api, {:insert, data, identifier})
  end

  @doc """
  Chord.lookup

  Lookup the data in the chord network
  """
  def lookup(api, data, identifier \\ nil) do
    GenServer.call(api, {:lookup, data, identifier})
  end

  @doc """
  Chord.broadcast

  Send message to every node in the chord network
  """
  def broadcast(api, message, data) do
    GenServer.cast(api, {:broadcast, message, data})
  end

  @doc """
  Chord.send_peers

  Send message only to the peers of the node
  """
  def send_peers(api, message, payload \\ nil) do
    GenServer.cast(api, {:send_peers, message, payload})
  end

  ###                      ###
  ###                      ###
  ### GenServer Callbacks  ###
  ###                      ###
  ###                      ###

  @doc """
  Chord.init

  Initiate the api genserver with given options  and join the node with the chord network
  """
  @impl true
  def init(opts) do
    ip_addr = Keyword.get(opts, :ip_addr)
    seed_server = Keyword.get(opts, :seed_server)
    identifier = Keyword.get(opts, :identifier)
    number_of_bits = Keyword.get(opts, :number_of_bits)
    distributed_store = Keyword.get(opts, :distributed_store)
    store = Keyword.get(opts, :store)

    {:ok, node} =
      Chord.Node.start_link(
        ip_addr: ip_addr,
        seed_server: seed_server,
        identifier: identifier,
        number_of_bits: number_of_bits,
        distributed_store: distributed_store,
        store: store
      )

    Chord.Node.join(node)
    Process.flag(:trap_exit, true)
    {:ok, {node, number_of_bits}}
  end

  @doc """
  Chord callback for `:insert`

  Calculates the hash for the data, finds it's node and inserts it into that node
  """
  @impl true
  def handle_call({:insert, data, identifier}, {pid, ref}, {node, number_of_bits}) do
    # Get a unique key for the data
    key = identifier || :crypto.hash(:sha, data) |> binary_part(0, div(number_of_bits, 8))
    GenServer.reply({pid, ref}, {:reply, :ok})

    # Find a node responsible for storing the key
    _reply = Chord.Node.find_successor(node, key, 0)

    {successor, _hops} =
      receive do
        {:successor, {successor, hops}} -> {successor, hops}
      end

    # Successor may be node itself or some other node in the ring
    # Write the data using block storage server of that node
    response = Chord.Node.insert(successor[:pid], key, data)
    send(pid, {:insert_result, {successor, response}})
    {:noreply, {node, number_of_bits}}
  end

  @doc """
  Chord callback for `:lookup`

  Calculates the hash for the data and finds the node it resides on 
  """
  @impl true
  def handle_call({:lookup, data, identifier}, {pid, ref}, {node, number_of_bits}) do
    # Get the hash value for the data
    key = identifier || :crypto.hash(:sha, data) |> binary_part(0, div(number_of_bits, 8))
    GenServer.reply({pid, ref}, {:reply, :ok})

    # Find the node
    _reply = Chord.Node.find_successor(node, key, 0)

    {successor, hops} =
      receive do
        {:successor, {successor, hops}} -> {successor, hops}
      end

    # Read  the data using block storage server of that node
    {item, from} = Chord.Node.lookup(successor[:pid], key)
    send(pid, {:lookup_result, {item, from, hops}})
    {:noreply, {node, number_of_bits}}
  end

  @doc """
  Chord callback to create a broadcast
  """
  @impl true
  def handle_cast({:broadcast, message, payload}, {node, _} = state) do
    IO.puts("initiating broadcast from api....")
    Chord.Node.initiate_broadcast(node, message, payload)
    {:noreply, state}
  end

  @doc """
  Chord.handle_cast callback for `:send_peers`

  Send message only to the peers of the node
  """
  @impl true
  def handle_cast({:send_peers, message, payload}, {node, _} = state) do
    Chord.Node.send_peers(node, message, payload)
    {:noreply, state}
  end

  @doc """
  Chord callback for `terminate`

  Kills the node process and sets off the chain to kill the processes in node
  """
  @impl true
  def terminate(_reason, {node, _}) do
    # IO.inspect("Terminating api #{inspect(reason)}")
    Process.exit(node, :normal)
  end
end
