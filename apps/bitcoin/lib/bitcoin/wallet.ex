defmodule Bitcoin.Wallet do
  use GenServer

  alias Bitcoin.Utilities.Keys

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    private_key = Keys.generate_private_key()
    public_key = Keys.to_public_key(private_key)
    bitcoin_address = Keys.to_public_address(private_key)
    {:ok, [private_key: private_key, public_key: public_key, bitcoin_address: bitcoin_address]}
  end
end
