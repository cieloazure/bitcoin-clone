defmodule Bitcoin.Node do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def sync(node) do
    GenServer.cast(node, {:sync})
  end

  def init(opts) do
    ip_addr = Keyword.get(opts, :ip_addr)
    seed = Keyword.get(opts, :seed)

    {:ok, blockchain} =
      Bitcoin.Blockchain.start_link(genesis_block: genesis_block(), node: self())

    {:ok, chord_api} =
      Chord.start_link(ip_addr: ip_addr, common_store: blockchain, seed_server: seed)

    {:ok, [ip_addr: ip_addr, blockchain: blockchain, chord_api: chord_api]}
  end

  def handle_cast({:sync}, state) do
    top_hash = Bitcoin.Blockchain.get_top_hash(state[:blockchain])
    Chord.send_peers(state[:chord_api], :getblocks, {self(), top_hash})
    {:noreply, state}
  end

  def handle_info({:blockchain_handler, message, payload}, state) do
    send(state[:blockchain], {:handle_message, message, payload})
  end

  ###
  defp genesis_block do
    genesis_transaction = %Bitcoin.Schemas.Transaction{}

    %Bitcoin.Schemas.Block{
      block_index: 0,
      block_size: 10,
      tx_counter: 1,
      txs: [genesis_transaction]
    }
  end
end
