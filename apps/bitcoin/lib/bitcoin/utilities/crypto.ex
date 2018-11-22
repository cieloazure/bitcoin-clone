defmodule Bitcoin.Utilities.Crypto do
  @module"""
  Module to handle various operations of the erlang crypto library
  Can be imported into another module to use functions in this library
  """

  @doc """
  SHA256 hash without serialization
  """
  def sha256(data) when is_bitstring(data) do
    :crypto.hash(:sha256, data)
  end

  @doc """
  sha256 hash with serialization
  """
  def sha256(data) do
    :crypto.hash(:sha256, serialize(data))
  end

  @doc """
  doublesha256 with serialization
  """
  def double_sha256(data) do
    serialize(data) |> sha256() |> sha256()
  end

  @doc """
  ripemd160 hash with serialization
  """
  def ripemd160(data) do
    :crypto.hash(:ripemd160, serialize(data))
  end

  @doc """
  Generalized function to use any hash algorithm
  """
  def hash(data, algorithm) do
    :crypto.hash(algorithm, data)
  end

  # Serialize the data for further processing
  defp serialize(data) do
    :erlang.term_to_binary(data)
  end
end
