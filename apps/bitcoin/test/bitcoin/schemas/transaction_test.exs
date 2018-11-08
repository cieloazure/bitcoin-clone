defmodule Bitcoin.Schemas.TransactionTest do
  use ExUnit.Case

  test "get defaults values in transaction struct" do
    transaction = %Bitcoin.Schemas.Transaction{}
    assert !is_nil(transaction)
  end

  test "initialize the transaction with values" do
    transaction = %Bitcoin.Schemas.Transaction{input_counter: 1, output_counter: 1}
    assert Map.get(transaction, :input_counter) == 1
  end

  test "update the transaction with new values" do
    transaction = %Bitcoin.Schemas.Transaction{input_counter: 1, output_counter: 1}
    assert Map.get(transaction, :input_counter) == 1

    {_, new_transaction} =
      Map.get_and_update(transaction, :input_counter, fn item -> {item, 2} end)

    assert Map.get(new_transaction, :input_counter) == 2
  end
end
