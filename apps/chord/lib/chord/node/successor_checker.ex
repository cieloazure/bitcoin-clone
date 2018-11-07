defmodule Chord.Node.SuccessorChecker do
  require Logger
  @mongering_interval 5000

  @doc """
  Start the ticker for stabalizer
  Will keep receiving tick events of the form `{:tick, _index}` at every `@mongering_interval` time
  """
  def start(pid) do
    Ticker.start(pid, @mongering_interval)
  end

  @doc """
  Stop the ticker for stabalizer
  Will send a event of `{:last_tick, index}` to the fact monger
  """
  def stop(pid) do
    Ticker.stop(pid)
  end

  def run(node_pid, ticker_pid) do
    receive do
      {:tick, _index} ->
        _response = Chord.Node.ping_successor(node_pid, self())

        receive do
          {:ping_reply, :ok, _pid} ->
            nil

          {:ping_reply, :succ_absent} ->
            nil

          {:ping_reply, :succ_not_responding} ->
            Chord.Node.failed_successor(node_pid)
        after
          20000 ->
            Chord.Node.failed_successor(node_pid)
        end

        run(node_pid, ticker_pid)

      {:run_succ_checker} ->
        ticker_pid = start(self())
        run(node_pid, ticker_pid)

      {:last_tick, _index} ->
        :ok

      {:stop, _reason} ->
        stop(ticker_pid)
        run(node_pid, ticker_pid)
    end
  end
end
