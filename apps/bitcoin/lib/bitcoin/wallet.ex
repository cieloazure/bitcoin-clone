defmodule Bitcoin.Wallet do
  @moduledoc """
  A module for managing a wallet
  """
  alias Bitcoin.Structures.{Block, Chain}
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
      sub_chain =
        Chain.get_blocks(chain, fn b ->
          Block.get_attr(b, :height) > Block.get_attr(block, :height)
        end)

      # Collect unspent transaction_outputs from the above set
      Enum.filter(user_txos, fn txo ->
        txo_hash = Map.get(txo, :tx_hash)
        txo_index = Map.get(txo, :output_index)

        try do
          Enum.each(sub_chain, fn blk ->
            tx_inputs = Map.get(blk, :txns) |> Map.get(:inputs)

            for txi <- tx_inputs do
              txi_hash = Map.get(txi, :tx_hash)
              txi_index = Map.get(txi, :output_index)

              if txi_hash == txo_hash and txi_index == txo_index,
                do: throw(:break)
            end
          end)
        catch
          :break -> false
        end

        true
      end)
    end)
  end

  defp verify_signature(tx_output, unlocking_script) do
    locking_script = Map.get(tx_output, :locking_script)
    script = unlocking_script <> " / " <> locking_script

    ScriptUtil.valid?(script)
  end
end
