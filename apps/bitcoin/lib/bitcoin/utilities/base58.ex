defmodule Bitcoin.Utilities.Base58 do
  @moduledoc """
  This module is responsible for encoding in a Base58 format which encodes string in unambiguous characters
  """
  @alphabet '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

  @doc """
  encode

  Base58 encoding algorithm
  """
  def encode(data, hash \\ "")

  def encode(0, hash), do: hash

  def encode(data, hash) when is_binary(data) do
    IO.inspect(encode_zeros(data))
    encode_zeros(data) <> encode(:binary.decode_unsigned(data), hash)
  end

  def encode(data, hash) do
    character = <<Enum.at(@alphabet, rem(data, 58))>>
    encode(div(data, 58), hash <> character)
  end

  #### PRIVATE FUNCTION ####

  # Handle the leading zeros which are truncated in default behaviour
  defp leading_zeros(data) do
    :binary.bin_to_list(data)
    |> Enum.find_index(&(&1 != 0))
  end

  # Handle zeros separately as elixir truncates the zeros
  defp encode_zeros(data) do
    <<Enum.at(@alphabet, 0)>>
    |> String.duplicate(leading_zeros(data))
  end
end
