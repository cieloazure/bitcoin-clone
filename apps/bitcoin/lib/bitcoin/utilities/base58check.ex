defmodule Bitcoin.Utilities.Base58Check do
  @moduledoc """
  Base58 encoding with version and checksum included
  """

  @doc """
  Base58Check encoding algorithm
  """
  def encode(version, data) do
    (version <> data <> checksum(version, data))
    |> Bitcoin.Utilities.Base58.encode()
  end

  ### PRIVATE FUNCTION ###

  # checksum
  defp checksum(version, data) do
    (version <> data)
    |> sha256
    |> sha256
    |> split
  end

  # Get the first four bytes for checksum
  defp split(<<hash::bytes-size(4), _::bits>>), do: hash
  defp sha256(data), do: :crypto.hash(:sha256, data)
end
