defmodule Bitcoin.Utilities.Keys do
  @moduledoc """
  Keys utility to manage keys
  """
  alias Bitcoin.Utilities.Base58Check, as: Base58Check

  @doc """
  Generate a private key
  """
  def generate_private_key() do
    private_key = :crypto.strong_rand_bytes(32)

    case valid?(private_key) do
      true -> private_key
      false -> generate_private_key()
    end
  end

  @doc """
  Get a public key from the private key
  """
  def to_public_key(private_key) do
    :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), private_key)
    |> elem(0)
  end

  @doc """
  Get a compressed form of public key from the private key
  """
  def to_compressed_public_key(private_key) do
    {<<0x04, x::binary-size(32), y::binary-size(32)>>, _} =
      :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), private_key)

    if rem(:binary.decode_unsigned(y), 2) == 0 do
      <<0x02>> <> x
    else
      <<0x03>> <> x
    end
  end

  @doc """
  Get a public key hash
  """
  def to_public_hash(private_key) do
    private_key
    |> to_public_key
    |> hash(:sha256)
    |> hash(:ripemd160)
  end

  @doc """
  Get bitcoin address for transactions
  """
  def to_public_address(private_key, version \\ <<0x00>>) do
    public_hash =
      private_key
      |> to_public_hash

    Base58Check.encode(version, public_hash)
  end

  @doc """
  Check the validity of private key
  """
  def valid?(private_key) when is_binary(private_key) do
    private_key |> :binary.decode_unsigned() |> valid?
  end

  def valid?(key) do
    {_, _, _, order, _} = :crypto.ec_curve(:secp256k1)

    if(key > 1 and key < :binary.decode_unsigned(order)) do
      true
    else
      false
    end
  end

  def hash(data, algorithm), do: :crypto.hash(algorithm, data)
end
