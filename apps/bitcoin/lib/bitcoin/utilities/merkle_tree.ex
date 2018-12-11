defmodule Bitcoin.Utilities.MerkleTree do
  @moduledoc """
  Module to implement merkle tree functionalities.
  Can construct a merkle tree as well as get the authentication path of a leaf from the merkle tree
  """
  alias Bitcoin.Utilities.Stack
  import Bitcoin.Utilities.Crypto
  require Logger

  @doc """
  Calculate the merkle root and merkle tree
  """
  def calculate_hash(items) when is_list(items) and length(items) > 0 do
    items =
      if rem(length(items), 2) != 0 do
        ritems = Enum.reverse(items)
        ritems = [List.first(ritems) | ritems]
        Enum.reverse(ritems)
      else
        items
      end

    merkle_tree =
      Enum.reduce(0..(trunc(:math.log2(length(items))) + 1), %{}, fn x, acc ->
        Map.put(acc, x, [])
      end)

    tree_hash(items, [], merkle_tree)
  end

  @doc """
  Get the authentication path of each leaf
  """
  def authentication_path(merkle_tree, _leaf \\ nil) do
    items = Map.get(merkle_tree, 0)
    max_height = trunc(:math.log2(length(items)))

    auth =
      Enum.reduce(0..(max_height - 1), %{}, fn x, acc ->
        level = Map.get(merkle_tree, x)
        item = Enum.at(level, 1)
        Map.put(acc, x, item)
      end)

    stack =
      Enum.reduce(0..(max_height - 1), %{}, fn x, acc ->
        level = Map.get(merkle_tree, x)
        item = Enum.at(level, 0)
        Map.put(acc, x, {[item], nil, nil})
      end)

    auth_paths = %{}

    calc_auth_path(auth, stack, 0, auth_paths, max_height, merkle_tree, length(items))
  end

  # Helper methods to calculate the authentication path
  defp calc_auth_path(auth, stack, leaf, auth_paths, max_height, merkle_tree, nodes)
       when leaf < nodes do
    auth_paths = Map.put(auth_paths, leaf, auth)
    h = 0
    factor = trunc(:math.pow(2, h))
    {auth, stack} = update_auth(leaf, h, factor, auth, stack, max_height)
    stack = update_stack(stack, merkle_tree, 0, max_height, nodes)
    # IO.inspect(auth)
    # IO.inspect(stack)
    calc_auth_path(auth, stack, leaf + 1, auth_paths, max_height, merkle_tree, nodes)
  end

  defp calc_auth_path(_, _, _, auth_paths, _, _, _) do
    auth_paths
  end

  ###########

  defp update_stack(stack_collection, merkle_tree, height, max_height, max_nodes)
       when height < max_height do
    {stack, start_node, ini_height} = Map.get(stack_collection, height)

    stack =
      cond do
        # do something
        Stack.size(stack) == 2 ->
          update_stack_proc(stack, merkle_tree, ini_height, start_node)

        Stack.empty?(stack) and is_nil(start_node) and is_nil(ini_height) ->
          []

        Stack.empty?(stack) and start_node >= max_nodes ->
          []

        Stack.empty?(stack) and !is_nil(start_node) and !is_nil(ini_height) ->
          update_stack_proc(stack, merkle_tree, ini_height, start_node)

        Stack.size(stack) == 1 and is_nil(start_node) and is_nil(ini_height) ->
          stack
      end

    {_, stack_collection} =
      Map.get_and_update(stack_collection, height, fn current_value ->
        {current_value, {stack, nil, nil}}
      end)

    update_stack(stack_collection, merkle_tree, height + 1, max_height, max_nodes)
  end

  defp update_stack(stack_collection, _merkle_tree, _height, _max_height, _nodes) do
    stack_collection
  end

  defp update_stack_proc(stack, _, height, start_node)
       when is_nil(height) and is_nil(start_node) and length(stack) == 1 do
    stack
  end

  defp update_stack_proc(stack, merkle_tree, height, start_node) do
    if Stack.empty?(stack) do
      items = Map.get(merkle_tree, 0)
      item1 = Enum.at(items, start_node)
      stack = Stack.push(stack, item1)
      height = height - 1

      if height >= 0 do
        item2 = Enum.at(items, start_node + 1)
        Stack.push(stack, item2)
      else
        stack
      end
    else
      if Stack.size(stack) == 2 do
        {item1, stack} = Stack.pop(stack)
        {item2, stack} = Stack.pop(stack)
        hash_item = (serialize(item1) <> serialize(item2)) |> sha256
        Stack.push(stack, hash_item)
      else
        stack
      end
    end
  end

  defp update_auth(leaf, height, factor, auth, stack, max_height)
       when rem(leaf + 1, factor) == 0 and height < max_height do
    {stack1, _, _} = Map.get(stack, height)

    stack_val =
      if Stack.empty?(stack1) do
        nil
      else
        List.first(stack1)
      end

    auth = Map.put(auth, height, stack_val)
    start_node = :crypto.exor(<<leaf + 1 + factor>>, <<factor>>) |> :binary.decode_unsigned()

    {_, stack} =
      Map.get_and_update(stack, height, fn current_value ->
        {current_value, {[], start_node, height}}
      end)

    factor = trunc(:math.pow(2, height + 1))
    update_auth(leaf, height + 1, factor, auth, stack, max_height)
  end

  defp update_auth(leaf, height, _factor, auth, stack, max_height) when height < max_height do
    factor = trunc(:math.pow(2, height + 1))
    update_auth(leaf, height + 1, factor, auth, stack, max_height)
  end

  defp update_auth(_leaf, _height, _factor, auth, stack, _max_height) do
    {auth, stack}
  end

  #######

  defp tree_hash(items, stack, output) when length(items) == 0 and length(stack) == 1 do
    {{root_hash, _height}, _} = Stack.pop(stack)
    {root_hash, output}
  end

  defp tree_hash(items, stack, output) do
    peek = Stack.peek(stack, 2)

    if !is_nil(peek) and equal_height?(peek) do
      {[{item1, height}, {item2, height}], stack} = Stack.pop(stack, 2)
      item = (serialize(item1) <> serialize(item2)) |> sha256
      stack = Stack.push(stack, {item, height + 1})

      {_, output} =
        Map.get_and_update(output, height + 1, fn current_array ->
          {current_array, current_array ++ [item]}
        end)

      tree_hash(items, stack, output)
    else
      {item, items} = List.pop_at(items, 0)
      hash_item = sha256(serialize(item))
      stack = Stack.push(stack, {hash_item, 0})

      {_, output} =
        Map.get_and_update(output, 0, fn current_array ->
          {current_array, current_array ++ [hash_item]}
        end)

      tree_hash(items, stack, output)
    end
  end

  defp equal_height?(items) when length(items) < 2, do: false
  defp equal_height?([item1, item2]), do: elem(item1, 1) == elem(item2, 1)
  defp serialize(term), do: :erlang.term_to_binary(term)
end
