defmodule Bitcoin.Structures.TransactionTest do
  use ExUnit.Case
  alias Bitcoin.Structures.Transaction
  import DummyData

  describe "valid transactions" do
    test "create generation transaction" do
      {:ok, gen_tx} =
        Transaction.create_generation_transaction(1, 1000, wallet1() |> Keyword.get(:address))

      assert Bitcoin.Schemas.Transaction.valid?(gen_tx)
    end

    test "create transaction" do
      chain = get_chain()
      wallet = wallet1()
      recipient = wallet2() |> Keyword.get(:address)
      utxo = Bitcoin.Wallet.collect_utxo(wallet[:public_key], wallet[:private_key], chain)

      {:ok, transaction} = Transaction.create_transaction(wallet, recipient, utxo, 10_000)

      assert Bitcoin.Schemas.Transaction.valid?(transaction)
    end

    test "valid transaction" do
      chain = get_chain()
      assert Bitcoin.Schemas.Transaction.valid?(tx5())
      assert Transaction.valid?(tx5(), chain, [])
    end
  end

  describe "invalid transactions" do
    test "duplicate transaction exists in chain" do
      chain = get_chain()
      assert Bitcoin.Schemas.Transaction.valid?(tx4())
      assert !Transaction.valid?(tx4(), chain, [])
    end

    test "duplicate transaction exists in pool" do
      chain = get_chain()
      assert Bitcoin.Schemas.Transaction.valid?(tx5())
      assert !Transaction.valid?(tx5(), chain, [tx5()])
    end

    test "reusing spent transaction input" do
      chain = get_chain()
      assert Bitcoin.Schemas.Transaction.valid?(inv_tx1())
      assert !Transaction.valid?(inv_tx1(), chain, [])
    end

    test "incorrect unlocking script" do
      chain = get_chain()
      assert Bitcoin.Schemas.Transaction.valid?(inv_tx2())
      assert !Transaction.valid?(inv_tx2(), chain, [])
    end
  end
end
