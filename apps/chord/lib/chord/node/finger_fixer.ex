defmodule Chord.Node.FingerFixer do
  require Logger
  @mongering_interval 100

  @doc """
  Chord.Node.FingerFixer.start

  Start the ticker for stabalizer
  Will keep receiving tick events of the form `{:tick, _index}` at every `@mongering_interval` time
  """
  def start(pid) do
    Ticker.start(pid, @mongering_interval)
  end

  @doc """
  Chord.Node.FingerFixer.stop

  Stop the ticker for stabalizer
  Will send a event of `{:last_tick, index}` to the fact monger
  """
  def stop(pid) do
    Ticker.stop(pid)
  end

  @doc """
  Chord.Node.FingerFixer.run

  A method to run the receive loop. This method will receive various events like - 
  *{:tick, _index} -> Receives a periodic event from `Ticker`
  *{:fix_fingers, next, finger_table} -> Received when the node joins a chord network and needs to initialize its finger table
  *{:update_finger_table, new_finger_table} -> Received when a finger table has been updated in the node and needs to be updated in this process as well
  """
  def run(next, m, node_identifier, node_pid, finger_table, ticker_pid) do
    receive do
      # Event: tick, a periodic tick received from Ticker
      {:tick, _index} ->
        next = next + 1

        next =
          if next > m do
            1
          else
            next
          end

        next_finger_id =
          if is_binary(node_identifier) do
            :binary.encode_unsigned(
              rem(
                :crypto.bytes_to_integer(node_identifier) + round(:math.pow(2, next - 1)),
                round(:math.pow(2, m))
              )
            )
          else
            rem(node_identifier + round(:math.pow(2, next - 1)), round(:math.pow(2, m)))
          end

        _reply =
          Chord.Node.find_successor(
            node_pid,
            next_finger_id,
            0
          )

        {successor, _hops} =
          receive do
            {:successor, {successor, hops}} -> {successor, hops}
          end

        new_finger_table = Map.put(finger_table, {next, next_finger_id}, successor)

        new_finger_table =
          if new_finger_table != finger_table do
            Chord.Node.update_finger_table(node_pid, new_finger_table)
            finger_table
          else
            finger_table
          end

        run(next, m, node_identifier, node_pid, new_finger_table, ticker_pid)

      # Event: Fix Fingers
      {:fix_fingers, next, finger_table} ->
        ticker_pid = start(self())

        run(next, m, node_identifier, node_pid, finger_table, ticker_pid)

      # Event: Update finger table
      {:update_finger_table, new_finger_table} ->
        run(next, m, node_identifier, node_pid, new_finger_table, ticker_pid)

      # Event: Last tick
      # TODO: When to use this?
      {:last_tick, _index} ->
        :ok

      # Event: Stop the finger fixer
      # TODO: When and if we have to use this?
      {:stop, _reason} ->
        stop(ticker_pid)
        run(next, m, node_identifier, node_pid, finger_table, ticker_pid)
    end
  end
end
