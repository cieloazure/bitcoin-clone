defmodule Bitcoin.Utilities.ConversionsTest do
  use ExUnit.Case
  import Bitcoin.Utilities.Conversions

  describe "hex_to_binary" do
    test "converts hex string to binary" do
      expected_binary = hex_to_binary("1D00FFFF")
      assert is_binary(expected_binary)
      assert expected_binary == <<29, 0, 255, 255>>
    end
  end

  describe "hex_to_decimal" do
    test "converts hex string to decimal" do
      expected_decimal = hex_to_decimal("03a30c")
      assert is_integer(expected_decimal)
      assert expected_decimal == 238_348
      assert is_integer(expected_decimal)
      expected_decimal = hex_to_decimal("B0")
      assert expected_decimal == 176
    end
  end

  describe "binary_to_hex" do
    test "converts binary to hex" do
      expected_hex = binary_to_hex(<<255>>)
      assert is_bitstring(expected_hex)
      assert expected_hex == "FF"
      expected_hex = binary_to_hex(<<176>>)
      assert is_bitstring(expected_hex)
      assert expected_hex == "B0"
      expected_hex = binary_to_hex(<<15>>)
      assert is_bitstring(expected_hex)
      assert expected_hex == "0F"
      expected_hex = binary_to_hex(<<29>>)
      assert is_bitstring(expected_hex)
      assert expected_hex == "1D"
    end
  end

  describe "binary_to_decimal" do
    test "converts binary to decimal" do
      expected_dec = binary_to_decimal(<<10>>)
      assert expected_dec == 10
      assert is_number(expected_dec)
    end
  end

  describe "decimal_to_binary" do
    test "converts decimal to binary" do
      expected_bin = decimal_to_binary(10)
      assert expected_bin == <<10>>
    end
  end

  describe "decimal_to_hex" do
    test "converts decimal to hex" do
      expected_hex =
        decimal_to_hex(
          22_829_202_948_393_929_850_749_706_076_701_368_331_072_452_018_388_575_715_328
        )

      assert expected_hex == "03A30C00000000000000000000000000000000000000000000"
    end
  end
end
