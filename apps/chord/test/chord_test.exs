defmodule ChordTest do
  use ExUnit.Case
    @moduledoc """
  A module to run the simulation
  """
  require Logger

  test "run simulation" do
    api_list = run(10, 10, 8)
    IO.inspect(api_list)
    api = List.first(api_list)
    IO.inspect(api)
    {node, _}  = :sys.get_state(api)
    IO.inspect(:sys.get_state(node))
    Chord.broadcast(api, :store, 42)
    Process.sleep(20000)
  end

  @doc """
  Simulation.run

  Main process to run the simulation. Accepts number of nodes, number of requests, number of bits and number of records as arguments
  """
  def run(num_nodes \\ 1000, num_requests \\ 10, number_of_bits \\ 40, num_records \\ 1000) do
    # create a location server for the nodes to get a node to join chord
    {:ok, location_server} = SeedServer.start_link([])

    # create `numNodes` number of nodes
    Logger.info("Creating Nodes....")

    api_list =
      for n <- 0..(num_nodes - 1) do
        ProgressBar.render(n, num_nodes - 1)

        {:ok, api} =
          Chord.start_link(
            ip_addr: get_ip_addr(),
            seed_server: location_server,
            number_of_bits: number_of_bits,
            identifier: n
          )

        Process.sleep(150)
        api
      end

    Logger.info("Waiting 5s for stabalization...")
    Process.sleep(5000)
    api_list

    # create dummy database and insert that data into the chord network using
    # random nodes

    #Logger.info("Inserting dummy  data for simulation....")

    #database =
      #for n <- 0..num_records do
        #ProgressBar.render(n, num_records)
        #data = get_random_string()
        #_r = Chord.insert(Enum.random(api_list), data)
        #data
      #end

    ## {api_list, database}

    #### Request for random data from each node for `numRequests` times
    #### Do this parallely
    #Logger.info("Sending #{num_requests} requests from each node....")

    #results =
      #api_list
      #|> Enum.map(&Task.async(fn -> request(&1, database, num_requests) end))
      #|> Enum.map(&Task.await(&1, :infinity))

    ### Collect the results for each request and the number of hops it required
    ### for each node
    #results = List.flatten(results)

    ### Calculate the average number of hops for each node
    #average_hops = Enum.reduce(results, 0, fn result, acc -> result + acc end) / length(results)
    #Logger.info("Average number of hops is: #{average_hops}")
  end

  # Get a random ip address
  defp get_ip_addr() do
    to_string(:rand.uniform(255)) <>
      "." <>
      to_string(:rand.uniform(255)) <>
      "." <> to_string(:rand.uniform(255)) <> "." <> to_string(:rand.uniform(255))
  end

  # Get a random string for data
  defp get_random_string() do
    length = :rand.uniform(100)
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  # Send num_requests for a api asynchronously
  defp request(api, database, num_requests) do
    Logger.debug("Sending requests from #{inspect(api)}")

    for n <- 1..num_requests do
      Process.sleep(1000)
      data = Enum.random(database)
      _reply = Chord.lookup(api, data)

      {_item, _from, hops} =
        receive do
          {:lookup_result, result} -> result
        end

      hops
    end
  end
end
