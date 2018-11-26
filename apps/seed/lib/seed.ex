defmodule SeedServer do
  @moduledoc """
  Seed Server to get a node n' to join a network.l  

  TODO:  A scalable solution to seed service. http://cs.brown.edu/~jj/papers/grid-mobicom00.pdf  
  """
  use GenServer
  require Logger

  ###
  ###
  ### Client API
  ###
  ###

  @doc """
  SeedServer.start_link

  Starts the seed server with given options
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: :seed_server)
  end

  @doc """
  SeedServer.node_request

  Handles the request for a node in the chord. 

  Returns a random node ip address if it exits, else return nil
  """
  def node_request(seed_server, from_ip) do
    GenServer.call(seed_server, {:node_request, from_ip})
  end

  ###
  ###
  ### GenServer Callbacks 
  ###
  ###

  @doc """
  SeedServer.init

  A genserver callback to initiate the state of the seed server
  """
  def init(_opts) do
    # A map of ip_address and process id
    # TODO: a map with information such as ip_address, coordinates, process_id,
    # etc. Consider a ets table for implementing such functionality
    nodes = %{}
    {:ok, nodes}
  end

  @doc """
  SeedServer.handle_call

  A genserver callback to handle the `:node_request` message from a node which is looking to join the chord network
  """
  def handle_call({:node_request, ip_address}, {from_pid, _from_ref}, nodes) do
    if Enum.empty?(nodes) do
      nodes = Map.put(nodes, from_pid, ip_address)
      {:reply, nil, nodes}
    else
      node = Enum.random(nodes)
      nodes = Map.put(nodes, from_pid, ip_address)
      {:reply, node, nodes}
    end
  end
end
