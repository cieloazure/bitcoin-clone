defmodule Bitcoin.Utilities.Crypto do
  def sha256(data) when is_bitstring(data) do
    :crypto.hash(:sha256, data)
  end

  def sha256(data) do
    :crypto.hash(:sha256, serialize(data))
  end

  def double_sha256(data) do
    serialize(data) |> sha256() |> sha256()
  end

  def ripemd160(data) do
    :crypto.hash(:ripemd160, serialize(data))
  end

  def hash(data, algorithm) do
    :crypto.hash(algorithm, data)
  end

  defp serialize(data) do
    :erlang.term_to_binary(data)
  end
end
