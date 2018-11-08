defmodule Chord.Node.FindSuccessor do
  @moduledoc """
  A helper module to reduce the bottleneck by separating out find successor and running it concurrently
  """

  @doc """
   Chord.Node.find_successor_concurrent

   A helper function to run the find_successor in concurrent as multiple
   process may request for find_successor and the genserver will become
   a bottleneck
  """
  def find_successor_concurrent(id, hops, {pid, _ref}, state, our_pid) do
    # Check if connected to chord 
    if is_nil(state[:successor]) do
      send(pid, {:successor, {nil, hops}})
    else
      if Helpers.CircularInterval.half_open_interval_check(
           id,
           state[:identifier],
           state[:successor][:identifier]
         ) do
        # Check in the interval
        send(pid, {:successor, {state[:successor], hops}})
      else
        # Check finger table
        preceding_node = closest_preceding_node(id, our_pid, state)

        if preceding_node[:pid] == our_pid do
          self_successor = [
            identifier: state[:identifier],
            ip_addr: state[:ip_addr],
            pid: our_pid
          ]

          send(pid, {:successor, {self_successor, hops}})
        else
          hops = hops + 1
          _reply = Chord.Node.find_successor(preceding_node[:pid], id, hops)

          receive do
            {:successor, {successor, hops}} ->
              send(pid, {:successor, {successor, hops}})
          end
        end
      end
    end
  end

  # Chord.Node.closest_preceding_node
  # A helper function for `find_successor` callback implementation which
  # iterates through the finger table to find the node which is closest
  # predeccessor of the given id
  defp closest_preceding_node(id, our_pid, state) do
    item =
      Enum.reverse(state[:finger_table])
      |> Enum.find(fn {_idx,
                       [
                         identifier: entry_identifier,
                         ip_addr: _entry_ip_addr,
                         pid: _entry_pid
                       ]} ->
        Helpers.CircularInterval.open_interval_check(entry_identifier, state[:identifier], id)
      end)

    if !is_nil(item) do
      {_key, value} = item
      value
    else
      [identifier: state[:identifier], ip_addr: state[:ip_addr], pid: our_pid]
    end
  end
end
