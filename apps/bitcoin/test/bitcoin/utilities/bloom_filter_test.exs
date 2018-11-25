defmodule Bitcoin.Utilities.BloomFilterTest do
  use ExUnit.Case
  alias Bitcoin.Utilities.BloomFilter

  @size	10
  @rate 0.3
  @length 25

  test "initialize" do
    filter = BloomFilter.init(@size, @rate)
    assert !Enum.empty?(filter)
    assert !Enum.empty?(filter[:bits])
    assert filter[:length] == @length
  end

  test "filter contains item" do
  	filter = BloomFilter.init(@size, @rate)
  	filter = BloomFilter.put(filter, "test")

  	assert BloomFilter.contains?(filter, "test")
  end

  test "filter doesn't contain item" do
  	filter = BloomFilter.init(@size, @rate)
  	filter = BloomFilter.put(filter, "test")

  	assert !BloomFilter.contains?(filter, "not in filter") 
  end
end
