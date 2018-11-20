defmodule Bitcoin.Utilities.Conversions do
  def hex_to_binary(hex_number) when is_bitstring(hex_number) do
    {:ok, exponent} = String.upcase(hex_number) |> Base.decode16(case: :upper)
    exponent
  end

  def hex_to_decimal(hex_number) when is_bitstring(hex_number) do
    {:ok, exponent} = String.upcase(hex_number) |> Base.decode16(case: :upper)
    binary_to_decimal(exponent)
  end

  def binary_to_hex(binary_number) when is_bitstring(binary_number) do
    Base.encode16(binary_number, case: :upper)
  end

  def binary_to_decimal(binary_number) when is_bitstring(binary_number) do
    :binary.decode_unsigned(binary_number)
  end

  def decimal_to_binary(decimal_number) when is_number(decimal_number) do
    :binary.encode_unsigned(trunc(decimal_number), :big)
  end

  def decimal_to_hex(decimal_number) when is_number(decimal_number) do
    binary = decimal_to_binary(decimal_number)
    binary_to_hex(binary)
  end
end
