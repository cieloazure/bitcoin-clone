defmodule Chord.Node do
  @moduledoc """
  Chord.Node

  Module to simulate a node in chord network
  """
  use GenServer
  require Logger

  @default_number_of_bits 24
  @default_size_succ_list 24

  ###             ###
  ###             ###
  ### Client API  ###
  ###             ###
  ###             ###

  @doc """
  Chord.Node.start_link

  An API Method to start the node with given options
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Chord.Node.join

  An API method to initiate the chord network for this node by either adding the node to the existing network or creating a new network with this node as the first node in the network
  """
  def join(node) do
    GenServer.cast(node, {:join})
  end

  @doc """
  Chord.Node.find_successor

  An API method to find the successor of a given id
  """
  def find_successor(node, id, hops) do
    GenServer.call(node, {:find_successor, id, hops})
  end

  @doc """
  Chord.Node.update_finger_table

  An API method to update the finger table which passes on to the callback
  """
  def update_finger_table(node, new_finger_table) do
    GenServer.cast(node, {:update_finger_table, new_finger_table})
  end

  @doc """
  Chord.Node.notify

  An api method to "notify" about the node which thinks that it might be our predeccessor
  """
  def notify(node, new_predeccessor) do
    GenServer.cast(node, {:notify, new_predeccessor})
  end

  @doc """
  Chord.Node.get_predeccessor

  An api method to get the predeccessor of the node
  """
  def get_predeccessor(node) do
    GenServer.call(node, {:get_predeccessor})
  end

  @doc """
  Chord.Node.update_successor

  An api method to update the successor of the node
  """
  def update_successor(node, new_successor) do
    GenServer.cast(node, {:update_successor, new_successor})
  end

  @doc """
  Chord.Node.read

  An api method to read the data on the node
  # TODO: Move the distributed store logic to the distributed store module
  """
  def lookup(node, key) do
    GenServer.call(node, {:lookup, key}, :infinity)
  end

  @doc """
  Chord.Node.write

  An api method to write the data on node
  # TODO: Move the distributed store logic to the distributed store module
  """
  def insert(node, key, data) do
    GenServer.call(node, {:insert, key, data})
  end

  @doc """
  Chord.Node.transfer_keys

  An api method to transfer keys belonging to the predeccessor
  # TODO: Move the distributed store logic to the distributed store module
  """
  def transfer_keys(node, predeccessor_identifier, predeccessor_pid) do
    GenServer.cast(node, {:transfer_keys, predeccessor_identifier, predeccessor_pid})
  end

  @doc """
  Chord.Node.get_succ_list

  An api method to get the succ list of a node
  """
  def get_succ_list(node) do
    GenServer.call(node, {:get_succ_list})
  end

  @doc """
  Chord.Node.update_succ_list

  An api method to update the succ list
  """
  def update_succ_list(node, new_succ_list) do
    GenServer.cast(node, {:update_succ_list, new_succ_list})
  end

  @doc """
  Chord.Node.ping_successor

  Ping successor
  """
  def ping_successor(node, checker_pid) do
    GenServer.call(node, {:ping_succ, checker_pid})
  end

  @doc """
  Chord.Node.ping_predeccessor

  Ping predecessor
  """
  def ping_predeccessor(node, checker_pid) do
    GenServer.call(node, {:ping_pred, checker_pid})
  end

  @doc """
  Chord.Node.ping

  Ping self
  """
  def ping(node) do
    GenServer.call(node, {:ping})
  end

  @doc """
  Chord.Node.failed_predeccessor

  Predeccessor has failed
  """
  def failed_predeccessor(node) do
    GenServer.cast(node, {:failed_predeccessor})
  end

  @doc """
  Chord.Node.failed_successor

  Successor has failed
  """
  def failed_successor(node) do
    GenServer.cast(node, {:failed_successor})
  end

  @doc """
  Chord.Node.handle_broadcast

  Decide what to do when a broadcast message is received; it may either choose to propogate the broadcast or stop propogation
  """
  def handle_broadcast(node, message, payload \\ nil) do
    GenServer.cast(node, {:broadcast, message, payload})
  end

  @doc """
  Chord.Node.propogate_broadcast

  Propogate the broadcast to the node's peers
  """
  def propogate_broadcast(node, message, payload \\ nil) do
    GenServer.cast(node, {:propogate_broadcast, message, payload})
  end

  @doc """
  Chord.Node.send_peers

  Send a message only to the node's peers
  """
  def send_peers(node, message, payload \\ nil) do
    GenServer.cast(node, {:send_peers, message, payload})
  end

  ###                      ###
  ###                      ###
  ### GenServer Callbacks  ###
  ###                      ###
  ###                      ###

  @doc """
  Chord.Node.init

  A callback to initiate the state of the node. The state of the node includes the following- 
  * ip address of the node
  * ip address of the location server
  * m-bit identifier using sha1 where m is 160 bit
  * predeccessor of the node
  * successor of the node
  * finger table
  * pid of finger fixer
  * pid of stabalizer
  * pid of predeccessor checker
  * pid of successor checker
  """
  @impl true
  def init(opts) do
    # The variable `m` in the original paper
    # Number of bits used to represent the identifier. In the default case,
    # :crypto.hash(:sha, <ipaddress> | <data>) will give a 160 bit Bitstring
    # For testing purpose we consider number_of_bits to be 3 in order to reduce
    # the identifier space
    number_of_bits = Keyword.get(opts, :number_of_bits) || @default_number_of_bits

    # Get the ip address from the opts
    ip_addr = Keyword.get(opts, :ip_addr)

    # Check if the ip address is provided
    if is_nil(ip_addr),
      do: raise(ArgumentError, message: "A seed ip address is required for a node to initiate")

    # Assign a identifier based on the ip address 
    identifier =
      Keyword.get(opts, :identifier) ||
        :crypto.hash(:sha, ip_addr) |> binary_part(0, div(number_of_bits, 8))

    # Get the seed_server from the address
    seed_server = Keyword.get(opts, :seed_server)

    if is_nil(seed_server),
      do:
        raise(ArgumentError, message: "A Location Server is required for joining a chord network")

    # Finger table
    finger_table = %{}

    # finger_fixer
    finger_fixer =
      spawn(Chord.Node.FingerFixer, :run, [
        -1,
        number_of_bits,
        identifier,
        self(),
        finger_table,
        nil
      ])

    # stabalizer
    stabalizer = spawn(Chord.Node.Stabalizer, :run, [nil, identifier, ip_addr, self(), nil])

    # predeccessor checker
    predeccessor_checker = spawn(Chord.Node.PredecessorChecker, :run, [self(), nil])

    # successor checker
    successor_checker = spawn(Chord.Node.SuccessorChecker, :run, [self(), nil])

    # Distributed storage server
    # A store to manage keys by the whole network collectively
    # Data is distributed across various servers 

    distributed_store = Keyword.get(opts, :distributed_store)

    {:ok, distributed_store} =
      if(is_nil(distributed_store)) do
        Chord.Defaults.DistributedStore.start_link(node: self())
      else
        {:ok, distributed_store}
      end

    # Common storage server
    # Handling common storage utilities
    # E.g Broadcasted message which need to be stored on every peer in the
    # network

    store = Keyword.get(opts, :store)

    {:ok, store} =
      if(is_nil(store)) do
        Chord.Defaults.Store.start_link(node: self())
      else
        {:ok, store}
      end

    # Trap exits
    Process.flag(:trap_exit, true)

    {:ok,
     [
       ip_addr: ip_addr,
       identifier: identifier,
       seed_server: seed_server,
       predeccessor: nil,
       successor: nil,
       successor_list: nil,
       finger_table: finger_table,
       finger_fixer: finger_fixer,
       stabalizer: stabalizer,
       predeccessor_checker: predeccessor_checker,
       successor_checker: successor_checker,
       distributed_store: distributed_store,
       store: store
     ]}
  end

  @doc """
  Chord.Node.handle_cast for `:join`

  This callback is responsible for a node joining a chord network or creating a chord network if it is the only one
  It gets a node from the location server, if there is one,  with which the successor of this node is found
  It also intiates the `FingerFixer` process to periodically check the finger table

  Returns the new state of the node
  """
  @impl true
  def handle_cast({:join}, state) do
    # Get the random node from the location server
    chord_node = SeedServer.node_request(state[:seed_server], state[:ip_addr])
    # Logger.info(inspect(chord_node))

    # Check if the node exists, if it does then ask that node to find
    # a successor for this node
    # else create a new chord network
    state =
      if !is_nil(chord_node) do
        # Predeccessor is nil
        state = Keyword.put(state, :predeccessor, nil)

        {chord_node, _ip_addr} = chord_node
        _reply = Chord.Node.find_successor(chord_node, state[:identifier], 0)

        {successor, _hops} =
          receive do
            {:successor, {successor, hops}} -> {successor, hops}
          end

        Keyword.put(state, :successor, successor)
      else
        state = Keyword.put(state, :predeccessor, nil)
        succ_state = [identifier: state[:identifier], ip_addr: state[:ip_addr], pid: self()]
        state = Keyword.put(state, :successor, succ_state)

        succ_list =
          for _n <- 1..@default_size_succ_list do
            succ_state
          end

        Keyword.put(state, :successor_list, succ_list)
      end

    # keys from successor which belong to us
    if state[:successor][:pid] != self() do
      capture_successor_keys(state[:successor][:pid], state[:identifier], self())
    end

    # Initialize the finger table for this newly created node
    send(state[:finger_fixer], {:fix_fingers, 0, state[:finger_table]})

    # Start the stabalizer for this newly created node
    send(state[:stabalizer], {:run_stabalizer, state[:successor]})

    # start predeccessor checker
    send(state[:predeccessor_checker], {:run_pred_checker})

    # start succeessor checker
    send(state[:successor_checker], {:run_succ_checker})

    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for `:update_finger_table`

  A callback to handle the update of `state[:finger_table]` from  `Chord.Node.FingerFixer`. The `Chord.Node.FingerFixer` will run periodically and update the fingers in the finger table. The main node will update its state and pass on the new state to the `Chord.Node.FingerFixer` again which will use the new finger table to periodically run updates for the finger table 

  Returns the new state of the node with the finger table updated
  """
  @impl true
  def handle_cast({:update_finger_table, new_finger_table}, state) do
    state = Keyword.put(state, :finger_table, new_finger_table)
    send(state[:finger_fixer], {:update_finger_table, state[:finger_table]})
    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for `:notify`

  A callback for notify in which a node which thinks it might our predeccessor tells us to update our predeccessor field. We(the node in question) update it only if the predeccessor lies between the old predeccessor and our own value

  Returns the new state of the node with predeccessor field updated
  """
  @impl true
  def handle_cast({:notify, new_predeccessor}, state) do
    state =
      if is_nil(state[:predeccessor]) or
           Helpers.CircularInterval.open_interval_check(
             new_predeccessor[:identifier],
             state[:predeccessor][:identifier],
             state[:identifier]
           ) do
        Keyword.put(state, :predeccessor, new_predeccessor)
      else
        state
      end

    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for `:update_successor`

  A callback to update successor of the node during the stabalization process
  """
  @impl true
  def handle_cast({:update_successor, new_successor}, state) do
    state = Keyword.put(state, :successor, new_successor)
    send(state[:stabalizer], {:update_successor, new_successor})
    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for `:transfer_keys`

  A callback to transfer keys belonging to our predeccessor and remove those keys from our storage
  """
  @impl true
  def handle_cast({:transfer_keys, identifier, predeccessor}, state) do
    items =
      Chord.Defaults.DistributedStore.query(state[:distributed_store], fn {k, _v} ->
        k <= identifier
      end)

    Enum.each(items, fn {key, value} ->
      Chord.Defaults.DistributedStore.delete(state[:distributed_store], key)
      Chord.Node.insert(predeccessor, key, value)
    end)

    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for `:update_succ_list`

  A callback method to update the successor list
  """
  @impl true
  def handle_cast({:update_succ_list, new_succ_list}, state) do
    state = Keyword.put(state, :successor_list, new_succ_list)
    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for `failed_predeccessor`

  A callback method to handle what to do when a predeccessor fails
  """
  @impl true
  def handle_cast({:failed_predeccessor}, state) do
    # IO.inspect("--------in failed predeccessor---------- for #{state[:identifier]}")
    state = Keyword.put(state, :predeccessor, nil)
    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for `failed_successor`

  A callback method to handle what to do when a successor fails
  """
  @impl true
  def handle_cast({:failed_successor}, state) do
    # IO.inspect("---------in failed successor---------- for #{state[:identifier]}")

    # Find the next active successor
    new_successor =
      Enum.find(state[:successor_list], fn successor ->
        try do
          {reply, _pid} =
            if successor[:pid] != self() do
              Chord.Node.ping(successor[:pid])
            else
              {:ok, self()}
            end

          if reply == :ok, do: true
        catch
          :exit, _ ->
            false
        end
      end)

    # replace successor
    state = Keyword.put(state, :successor, new_successor)

    # reconcile
    their_succ_list =
      if new_successor[:pid] == self() do
        state[:successor_list]
      else
        Chord.Node.get_succ_list(new_successor[:pid])
      end

    state =
      if !is_nil(their_succ_list) do
        [_head | tail] = Enum.reverse(their_succ_list)
        their_succ_list_trunc = Enum.reverse(tail)
        our_succ_list = [new_successor | their_succ_list_trunc]
        Keyword.put(state, :successor_list, our_succ_list)
      end

    # Stabalizer stops unexpectedly
    # Not able to find the reason for the bug
    # Restart the stabalizer as a workaround
    # TODO: Find reason why it stops and fix it
    if(!Process.alive?(state[:stabalizer])) do
      stabalizer =
        spawn(Chord.Node.Stabalizer, :run, [nil, state[:identifier], state[:ip_addr], self(), nil])

      state = Keyword.put(state, :stabalizer, stabalizer)
      send(state[:stabalizer], {:run_stabalizer, state[:successor]})
    end

    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for :broadcast
  """
  @impl true
  def handle_cast({:handle_broadcast, message, payload}, state) do
    # Delegate it to common store
    send(state[:store], {:handle_message, message, payload})
    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for :propogate_broadcast
  """
  @impl true
  def handle_cast({:propogate_broadcast, message, payload}, state) do
    peers = [state[:predeccessor] | state[:successor_list]]

    Enum.each(peers, fn peer ->
      if peer[:pid] != self() do
        Chord.Node.handle_broadcast(peer[:pid], message, payload)
      end
    end)

    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_cast for :send_peers
  """
  @impl true
  def handle_cast({:send_peers, message, payload}, state) do
    peers = [state[:predeccessor] | state[:successor_list]]

    Enum.each(peers, fn peer ->
      if peer[:pid] != self() and peer[:pid] != nil do
        send(peer[:pid], {:store_handler, message, payload})
      end
    end)

    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_call for `:get_predeccessor`

  A callback to get the predeccessor of the node. This is needed in stabalizer in order to change the successor if a new node has joined
  """
  @impl true
  def handle_call({:get_predeccessor}, _from, state) do
    {:reply, state[:predeccessor], state}
  end

  @doc """
  Chord.Node.handle_call for `:write`

  A callback to write the data on the node using block storage server
  """
  @impl true
  def handle_call({:insert, key, data}, _from, state) do
    store = Keyword.get(state, :distributed_store)
    reply = Chord.Defaults.DistributedStore.write(store, key, data)
    {:reply, reply, state}
  end

  @doc """
  Chord.Node.handle_call for `:read`

  A callback to read the data on the node using block storage server
  """
  @impl true
  def handle_call({:lookup, key}, _from, state) do
    store = Keyword.get(state, :distributed_store)
    item = Chord.Defaults.DistributedStore.read(store, key)

    {:reply, {item, [identifier: state[:identifier], ip_addr: state[:ip_addr], pid: self()]},
     state}
  end

  @doc """
  Chord.Node.handle_call for `:find_successor`

  A callback to find the successor node for a sha id provided. Used in both `lookup(key)` and `n.join(n')` operations. In lookup it finds the successor for the `key` of the data. In join operation it find the node which should be the successor of that node.

  Returns `nil` if the node is not in the ring and therefore will not be able to find a successor
  Returns the `state[:successor]` which is its own successor if the id is less than that of the successor
  Returns the `successor` which it finds after delegating it to what it thinks is the  `closest_preceding_node` of the id in which case the `closest_preceding_node` takes the responsiblity of finding the successor
  """
  @impl true
  def handle_call({:find_successor, id, hops}, from, state) do
    _pid =
      spawn(Chord.Node.FindSuccessor, :find_successor_concurrent, [id, hops, from, state, self()])

    {:reply, :ok, state}
  end

  @doc """
  Chord.Node.handle_call for `:get_succ_list`

  A callback method to return the node's successor list
  """
  @impl true
  def handle_call({:get_succ_list}, _from, state) do
    {:reply, state[:successor_list], state}
  end

  @doc """
  Chord.Node.handle_call for `:ping_succ`

  A callback method to ping the successor of the node
  """
  @impl true
  def handle_call({:ping_succ, checker_pid}, {_pid, _ref} = from, state) do
    GenServer.reply(from, {:sent_ping_succ})
    # IO.inspect(Keyword.take(state, [:successor, :predeccessor, :successor_list, :identifier]))

    cond do
      # There is one successor node in network
      # Cannot call our own ping process
      !is_nil(state[:successor]) and state[:successor][:pid] == self() ->
        send(checker_pid, {:ping_reply, :ok, self()})

      # We are not our own successor
      !is_nil(state[:successor]) ->
        {reply, pid} =
          try do
            Chord.Node.ping(state[:successor][:pid])
          catch
            :exit, _ ->
              {nil, nil}
          end

        if !is_nil(reply) do
          send(checker_pid, {:ping_reply, reply, pid})
        else
          send(checker_pid, {:ping_reply, :succ_not_responding})
        end

      # Successor is empty
      # Rare case; should not take place
      true ->
        send(checker_pid, {:ping_reply, :succ_absent})
    end

    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_call callback for `ping_pred`

  A callback method to ping predeccessor of the node
  """
  @impl true
  def handle_call({:ping_pred, checker_pid}, {_pid, _ref} = from, state) do
    GenServer.reply(from, {:sent_ping_pred})

    if !is_nil(state[:predeccessor]) do
      {reply, pid} =
        try do
          Chord.Node.ping(state[:predeccessor][:pid])
        catch
          :exit, _ ->
            {nil, nil}
        end

      if !is_nil(reply) do
        send(checker_pid, {:ping_reply, reply, pid})
      else
        send(checker_pid, {:ping_reply, :pred_not_responding})
      end
    else
      send(checker_pid, {:ping_reply, :pred_absent})
    end

    {:noreply, state}
  end

  @doc """
  Chord.Node.handle_call callback for :ping

  A callback method to ping the node
  """
  @impl true
  def handle_call({:ping}, _from, state) do
    {:reply, {:ok, self()}, state}
  end

  @doc """
  Chord.Node.handle_info callback for peer operations
  """
  @impl true
  def handle_info({:store_handler, message, payload}, state) do
    send(state[:store], {:handle_message, message, payload})
    {:noreply, state}
  end

  @doc """
  Chord.Node.terminate 

  A callback method called when the node is terminated. Has the responsiblity of clean up.
  """
  @impl true
  def terminate(_reason, state) do
    # IO.inspect("Terminating node")
    # TODO: Implement an agent to recover data from crash
    Process.exit(state[:distributed_store], :kill)
    Process.exit(state[:store], :kill)
    Process.exit(state[:finger_fixer], :kill)
    Process.exit(state[:successor_checker], :kill)
    Process.exit(state[:predeccessor_checker], :kill)
    Process.exit(state[:stabalizer], :kill)
  end

  ###### PRIVATE FUNCTIONS ########
  # A helper function to transfer keys belonging to us from successor 
  defp capture_successor_keys(successor_pid, our_identifier, our_pid) do
    Chord.Node.transfer_keys(successor_pid, our_identifier, our_pid)
  end
end
