defmodule Chord.Node.Stabalizer do
  require Logger
  @mongering_interval 50

  @doc """
  Chord.Node.Stabalizer.start 

  Start the ticker for stabalizer
  Will keep receiving tick events of the form `{:tick, _index}` at every `@mongering_interval` time
  """
  def start(pid) do
    Ticker.start(pid, @mongering_interval)
  end

  @doc """
  Chord.Node.Stabalizer.stop

  Stop the ticker for stabalizer
  Will send a event of `{:last_tick, index}` to the fact monger
  """
  def stop(pid) do
    Ticker.stop(pid)
  end

  @doc """
   Chord.Node.Stabalizer.run

   Periodic runner for the stabalizer. A method to run the receive loop. This loop will receive various events like -
   * {:tick, _index} : A tick event which comes periodically from ticker which tells the node to check it's successor and in case of a new successor notify that new successor to change its predeccessor to itself
   * {:update_successor, new_successor} : A event to update the successor in the receive loop
   * {:run_stabalizer, new_successor}: A event to start the ticker and run the receive loop periodically
   * {:stop, reason} : A event to stop the timer
   * {:last_tick, _index}: A event when it's last tick of the ticker maybe used for any clean up work
  """
  def run(node_successor, node_identifier, node_ip_addr, node_pid, ticker_pid) do
    receive do
      # Event: tick
      {:tick, _index} ->
        old_successor = node_successor
        # x = successor.predeccessor
        predeccessor_of_successor = Chord.Node.get_predeccessor(node_successor[:pid])

        # Is there a change in successor?
        successor =
          if is_nil(predeccessor_of_successor) do
            old_successor
          else
            if(
              Helpers.CircularInterval.open_interval_check(
                predeccessor_of_successor[:identifier],
                node_identifier,
                node_successor[:identifier]
              )
            ) do
              predeccessor_of_successor
            else
              old_successor
            end
          end

        # Update successor if changed
        if successor != old_successor do
          Chord.Node.update_successor(node_pid, successor)
        end

        # Notify

        if successor[:pid] != node_pid do
          Chord.Node.notify(successor[:pid],
            identifier: node_identifier,
            ip_addr: node_ip_addr,
            pid: node_pid
          )

          # Reconcile successor list with successor, remove last entry and
          # prepend the successor to the list and store it as our successor
          # list
          their_succ_list = Chord.Node.get_succ_list(successor[:pid])
          our_old_succ_list = Chord.Node.get_succ_list(node_pid)

          if !is_nil(their_succ_list) do
            [_head | tail] = Enum.reverse(their_succ_list)
            their_succ_list_trunc = Enum.reverse(tail)
            our_succ_list = [successor | their_succ_list_trunc]

            if our_succ_list != our_old_succ_list do
              Chord.Node.update_succ_list(node_pid, our_succ_list)
            end
          end
        end

        run(node_successor, node_identifier, node_ip_addr, node_pid, ticker_pid)

      # Event: Update successor
      {:update_successor, new_node_successor} ->
        run(new_node_successor, node_identifier, node_ip_addr, node_pid, ticker_pid)

      # Event: Run stabalizer
      {:run_stabalizer, node_successor} ->
        ticker_pid = start(self())
        run(node_successor, node_identifier, node_ip_addr, node_pid, ticker_pid)

      # Event: Last tick
      # TODO: When and if we have  to use this?
      {:last_tick, _index} ->
        :ok

      # Event: Stop the finger fixer
      # TODO: When and if we have to use this?
      {:stop, _reason} ->
        stop(ticker_pid)
        run(node_successor, node_identifier, node_ip_addr, node_pid, ticker_pid)
    end
  end
end
