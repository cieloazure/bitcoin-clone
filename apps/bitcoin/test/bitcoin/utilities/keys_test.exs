defmodule Bitcoin.Utilities.KeysTest do
  use ExUnit.Case
  alias Bitcoin.Utilities.Keys

  describe "private key" do
    test "is 256 bits in size" do
      private_key = Keys.generate_private_key()
      assert byte_size(private_key) * 8 == 256
    end
  end

  describe "bitcoin address" do
    test "starts with 1" do
      private_key = Keys.generate_private_key()
      bitcoin_address = Keys.to_public_address(private_key)
      assert String.starts_with?(bitcoin_address, "1")
    end

    test "is base58 encoded" do
      private_key = Keys.generate_private_key()
      bitcoin_address = Keys.to_public_address(private_key)
      alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
      Enum.all?(String.to_charlist(bitcoin_address), fn char -> Enum.member?(alphabet, char) end)
    end
  end

  describe "public key" do
    test "is 520(32 * 8(x) + 32 * 8(y) + 8(prefix)) bits in size" do
      private_key = Keys.generate_private_key()
      public_key = Keys.to_public_key(private_key)
      assert byte_size(public_key) * 8 == 520
    end
  end

  describe "public key hash" do
    test "is 160 bits in size" do
      private_key = Keys.generate_private_key()
      public_key_hash = Keys.to_public_hash(private_key)
      assert byte_size(public_key_hash) * 8 == 160
    end
  end
end
