require IEx

defmodule Bitcoin.Wallet do
  @moduledoc """
  A module for managing a wallet
  """
  alias Bitcoin.Structures.{Block, Chain, Transaction}
  alias Bitcoin.Utilities.{Keys, ScriptUtil}

  @doc """
  Initialize the wallet variables
  """
  def init_wallet() do
    private_key = Keys.generate_private_key()
    public_key = Keys.to_public_key(private_key)
    address = Keys.to_public_address(private_key)
    [private_key: private_key, public_key: public_key, address: address]
  end

  @doc """
  Collect the Unspent Transacion outputs for the given address from the blockchain
  """
  def collect_utxo(public_key, private_key, chain) do
    IEx.pry()

    utxos =
      Enum.flat_map(chain, fn block ->
        txos =
          Map.get(block, :txns)
          |> Enum.flat_map(fn txn -> Map.get(txn, :outputs) end)

        unlocking_script = ScriptUtil.generate_unlocking_script(private_key, public_key)

        # All the transaction_outputs towards current user
        user_txos =
          Enum.filter(txos, fn txo ->
            verify_signature(txo, unlocking_script)
          end)

        # Chain of blocks succeeding current block
        # sub_chain =
        #   Chain.get_blocks(chain, fn b ->
        #     Block.get_attr(b, :height) >= Block.get_attr(block, :height)
        #   end)

        IEx.pry()
        # Collect unspent transaction_outputs from the above set
        utxo =
          Enum.filter(user_txos, fn txo ->
            Transaction.unspent_output?(txo, chain)
          end)

        utxo
      end)

    utxos
  end

  defp verify_signature(tx_output, unlocking_script) do
    locking_script = Map.get(tx_output, :locking_script)
    script = ScriptUtil.join(unlocking_script, locking_script)
    # script = unlocking_script <> " / " <> locking_script

    ScriptUtil.valid?(script)
  end
end
