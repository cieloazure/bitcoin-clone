defmodule Bitcoin.Mining do
  @moduledoc """
  Module for mining  and related methods
  """
  import Bitcoin.Utilities.Crypto
  import Bitcoin.Utilities.Conversions
  alias Bitcoin.Structures.Block
  require Logger

  def mine_async(candidate_block, bitcoin_node) do
    mined_block = initiate_mining(candidate_block)
    Bitcoin.Node.new_block_found(bitcoin_node, mined_block)
  end

  @doc """
  Initiate mining on a given `candidate_block`

  Returns the mined block which contains the nonce in its header for which the target was achieved
  """
  def initiate_mining(candidate_block) do
    target = Bitcoin.Structures.Block.calculate_target(candidate_block)
    # Logger.info("Starting to mine....to reach target #{inspect(target)}")
    mine_block(candidate_block, target)
  end

  # mine_block
  # Calculates the nonce for which the `candidate_block` achieves the
  # difficulty target
  # 
  # Returns the mined block with the calculated nonce
  defp mine_block(candidate_block, target) do
    zeros_required = 32 - (String.trim_leading(target, <<0>>) |> byte_size)
    zeros_required = if zeros_required < 0, do: 0, else: zeros_required
    header = Bitcoin.Structures.Block.get_attr(candidate_block, :block_header)
    # nonce = Bitcoin.Structures.Block.get_header_attr(candidate_block, :nonce)
    # IO.inspect(nonce)

    <<zeros_obtained_target::bytes-size(zeros_required), _::bits>> = target
    <<zeros_obtained_header::bytes-size(zeros_required), _::bits>> = header |> double_sha256

    hashed_value = header |> double_sha256
    v1 = binary_to_decimal(hashed_value)
    v2 = binary_to_decimal(target)

    if zeros_obtained_header == zeros_obtained_target and v1 <= v2 do
      # Logger.info("Done with mining....")
      # Logger.info(inspect(hashed_value))
      # Logger.info(inspect(target))
      # Logger.info(inspect(nonce))
      # Logger.debug(inspect(candidate_block))
      print_mined_block(candidate_block)
      candidate_block
    else
      increment_nonce(candidate_block)
      |> mine_block(target)
    end
  end

  # increment_nonce
  # Increments the nonce in the candidate block header and returns the block
  #
  # Returns the block with updated nonce
  defp increment_nonce(candidate_block) do
    header = Bitcoin.Structures.Block.get_attr(candidate_block, :block_header)
    nonce = Bitcoin.Structures.Block.get_header_attr(candidate_block, :nonce)
    header = %Bitcoin.Schemas.BlockHeader{header | nonce: nonce + 1}
    candidate_block = %Bitcoin.Schemas.Block{candidate_block | block_header: header}
    candidate_block
  end

  def print_mined_block(mined_block) do
    IO.puts("\n--------- NEW BLOCK MINED! ---------")
    IO.puts("* Stats:")
    IO.puts("  - Height: #{Block.get_attr(mined_block, :height)}")
    IO.puts("  - Transaction Counter: #{Block.get_attr(mined_block, :tx_counter)}")
    IO.puts("  - Difficulty: #{Block.get_header_attr(mined_block, :bits)}")

    IO.puts(
      "  - Nonce required to achieve that difficulty: #{
        Block.get_header_attr(mined_block, :nonce)
      }"
    )

    IO.puts("* Transactions Summary: ")
    print_transactions(Block.get_attr(mined_block, :txns))
  end

  defp print_transactions(transactions) do
    coinbase_transaction = List.first(transactions)
    coinbase_output = Map.get(coinbase_transaction, :outputs) |> List.first()
    coinbase_output_amount = Map.get(coinbase_output, :amount)

    coinbase_address =
      Map.get(coinbase_output, :locking_script) |> String.split(" / ") |> Enum.at(3)

    IO.puts(
      "  - Coinbase Transaction | Amount: #{coinbase_output_amount} | Recipient: #{
        coinbase_address
      }"
    )

    transactions_without_coinbase = Enum.slice(transactions, 1..-1)

    Enum.with_index(transactions_without_coinbase)
    |> Enum.each(fn {tx, idx} ->
      print_one_transaction(tx, idx)
    end)
  end

  defp print_one_transaction(transaction, index) do
    IO.puts("  - Transaction #{index + 1}")
    tx_inputs = Map.get(transaction, :inputs)
    IO.puts("      - TxID: #{Map.get(transaction, :tx_id)}")

    Enum.with_index(tx_inputs)
    |> Enum.each(fn {input, idx} ->
      IO.puts("     -  Tx Input #{idx + 1} - #{Map.get(input, :tx_id)}")
    end)

    tx_outputs = Map.get(transaction, :outputs)

    Enum.with_index(tx_outputs)
    |> Enum.each(fn {output, idx} ->
      IO.puts(
        "     -  Tx Output #{idx + 1} - | Amount: #{Map.get(output, :amount)} | Recipient: #{
          Map.get(output, :locking_script) |> String.split(" / ") |> Enum.at(3)
        }"
      )
    end)
  end
end
