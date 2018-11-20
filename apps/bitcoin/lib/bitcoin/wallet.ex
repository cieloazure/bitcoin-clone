defmodule Bitcoin.Wallet do
  @moduledoc """
  A module for managing a wallet
  """
  alias Bitcoin.Utilities.Keys

  @doc """
  Initialize the wallet variables
  """
  def init_wallet() do
    private_key = Keys.generate_private_key()
    public_key = Keys.to_public_key(private_key)
    bitcoin_address = Keys.to_public_address(private_key)
    [private_key: private_key, public_key: public_key, bitcoin_address: bitcoin_address]
  end
end
