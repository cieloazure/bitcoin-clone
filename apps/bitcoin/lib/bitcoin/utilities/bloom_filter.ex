require IEx

defmodule Bitcoin.Utilities.BloomFilter do
  @moduledoc """
  BloomFilter implementation for quick probabilistic searches.
  The data structure can quickly make a probabilistic guess whether
  an item exists in the set or not, but never gives a false negative.
  """

  @doc """
  Initiates a Bloom Filter, sets the required bit size.
  """
  def init(expected_size, false_positive_rate) do
    # n = expected_size
    # p = false_positive_rate
    hash_fns = [:sha, :ripemd160, :sha256]
    m = calculate_required_bits(expected_size, false_positive_rate)
    bits = List.duplicate(0, m)
    [bits: bits, length: m, hash_fns: hash_fns]
  end

  @doc """
  Puts the given item in the filter i.e. sets the bits corresponding 
  to item's hash values in the bit array to 1.
  """
  def put(filter, items) when is_list(items) do
    Enum.reduce(items, filter, fn item, acc ->
      put(acc, item)
    end)

    # Enum.map(items, fn item -> 
    #   put(filter, item)
    # end)
  end

  def put(filter, item) do
    bits =
      hash(item, filter[:hash_fns], filter[:length])
      |> Enum.reduce(filter[:bits], fn bit_number, bits ->
        List.replace_at(bits, bit_number, 1)
      end)

    Keyword.put(filter, :bits, bits)
  end

  @doc """
  Checks whether the given item may exist in the filter.
  """
  def contains?(filter, item) do
    hash(item, filter[:hash_fns], filter[:length])
    |> Enum.all?(fn x -> Enum.at(filter[:bits], x) == 1 end)
  end

  # Calculates the required size of bit array for the given parameters.
  defp calculate_required_bits(expected_size, false_positive_rate) do
    n = expected_size
    p = false_positive_rate
    round(-n * :math.log(p) / :math.pow(:math.log(2), 2))
  end

  # Calculates the bits to be set for the given item
  defp hash(item, hash_fns, length) do
    Enum.map(hash_fns, fn hash_fn ->
      :crypto.hash(hash_fn, item)
      |> Bitcoin.Utilities.Conversions.binary_to_decimal()
      |> rem(length)
    end)
  end
end
