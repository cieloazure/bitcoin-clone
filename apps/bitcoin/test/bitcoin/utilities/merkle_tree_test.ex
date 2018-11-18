defmodule Bitcoin.Utilities.MerkleTreeTest do
  use ExUnit.Case

  alias Bitcoin.Utilities.MerkleTree
  describe "treehash" do
    test "even elements" do
      items = [1,2,3,4,5,6,7,8]
      {_root_hash, merkle_tree} = MerkleTree.calculate_hash(items)
      assert has_correct_length?(merkle_tree)
    end

    test "odd elements" do
      items = [1,2,3,4,5,6,7]
      {_root_hash, merkle_tree} = MerkleTree.calculate_hash(items)
      assert has_correct_length?(merkle_tree)
    end

    test "hashed in right order" do
      items = [1,2,3,4,5,6,7,8]
      {_root_hash, merkle_tree} = MerkleTree.calculate_hash(items)
      x = serialize(1) |> sha256
      level = Map.get(merkle_tree, 0)
      assert Enum.at(level, 0) == x
    end
  end

  describe "auth path" do
    test "auth path is correct" do
      items = [1,2,3,4,5,6,7,8]
      {root_hash, merkle_tree} = MerkleTree.calculate_hash(items)
      auth_paths = MerkleTree.authentication_path(merkle_tree, nil)
      path = Map.get(auth_paths, 0)
      leaf = Enum.at(items, 0) 
      leaf = :crypto.hash(:sha256, :erlang.term_to_binary(leaf))
      verify = Enum.reduce(path, leaf, fn {_k, v}, acc -> 
        t = :erlang.term_to_binary(v) <> :erlang.term_to_binary(acc) 
        :crypto.hash(:sha256, t)
      end)
      assert verify == root_hash
    end
  end

  defp has_correct_length?(merkle_tree) do
    check = Enum.map(0..trunc(:math.log2(8)), fn n -> 
      level = Map.get(merkle_tree, n)
      case n do
        0 -> length(level) == 8
        1 -> length(level) == 4
        2 -> length(level) == 2
        3 -> length(level) == 1
      end
    end)
    Enum.all?(check)
  end

  defp sha256(data), do: :crypto.hash(:sha256, data)
  defp serialize(term), do: :erlang.term_to_binary(term)
end
