defmodule Ticker do
  require Logger
  # public api
  def start(recipient_pid, tick_interval, duration \\ :infinity) do
    # Process.monitor(pid) # what to do if the process is dead before this?
    # start a process whose only responsibility is to wait for the interval
    ticker_pid = spawn(__MODULE__, :loop, [recipient_pid, tick_interval, 0])
    # and send a tick to the recipient pid and loop back
    send(ticker_pid, :send_tick)
    schedule_terminate(ticker_pid, duration)
    # returns the pid of the ticker, which can be used to stop the ticker
    ticker_pid
  end

  def stop(ticker_pid) do
    send(ticker_pid, :terminate)
  end

  # internal api
  def loop(recipient_pid, tick_interval, current_index) do
    receive do
      :send_tick ->
        # send the tick event
        send(recipient_pid, {:tick, current_index})
        # schedule a self event after interval
        Process.send_after(self(), :send_tick, tick_interval)
        loop(recipient_pid, tick_interval, current_index + 1)

      :terminate ->
        # terminating
        :ok
        # NOTE: we could also optionally wire it up to send a last_tick event when it terminates
        send(recipient_pid, {:last_tick, current_index})

      oops ->
        Logger.error("received unexepcted message #{inspect(oops)}")
        loop(recipient_pid, tick_interval, current_index + 1)
    end
  end

  defp schedule_terminate(_pid, :infinity), do: :ok

  defp schedule_terminate(ticker_pid, duration),
    do: Process.send_after(ticker_pid, :terminate, duration)
end
