defmodule Bitcoin.Utilities.Base58Check do
  @moduledoc """
  Base58 encoding with version and checksum included
  """
  import Bitcoin.Utilities.Crypto

  @doc """
  Base58Check encoding algorithm
  """
  def encode(data, version \\ <<0x00>>) do
    (version <> data <> checksum(data, version))
    |> Bitcoin.Utilities.Base58.encode()
  end

  ### PRIVATE FUNCTION ###

  # checksum
  defp checksum(data, version \\ <<0x00>>) do
    (version <> data)
    |> sha256
    |> sha256
    |> split
  end

  # Get the first four bytes for checksum
  defp split(<<hash::bytes-size(4), _::bits>>), do: hash
end
