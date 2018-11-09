# defmodule Bitcoin.NodeTest do
#   use ExUnit.Case

#   test "sync operation without any peers will not change the blockchain" do
#     {:ok, seed} = SeedServer.start_link([])
#     {:ok, node} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
#     blockchain = :sys.get_state(node)[:blockchain]
#     {_n, g} = :sys.get_state(blockchain)
#     Bitcoin.Node.sync(node)
#     Process.sleep(1000)
#     {_n, g1} = :sys.get_state(blockchain)
#     assert g == g1
#   end

#   test "sync operation with one  peers will change the blockchain" do
#     {:ok, seed} = SeedServer.start_link([])
#     {:ok, node1} = Bitcoin.Node.start_link(ip_addr: "192.168.0.1", seed: seed)
#     blockchain1 = :sys.get_state(node1)[:blockchain]

#     hashes = ["1234", "5678", "2343"]
#     heights = [1, 2, 3]

#     new_items =
#       for i <- 0..2 do
#         %Bitcoin.Schemas.Block{
#           height: Enum.at(heights, i),
#           # hash: Enum.at(hashes, i)
#         }
#       end

#     send(blockchain1, {:handle_message, :inv, new_items})

#     {:ok, node2} = Bitcoin.Node.start_link(ip_addr: "192.168.0.2", seed: seed)
#     blockchain2 = :sys.get_state(node2)[:blockchain]
#     {_n, g1} = :sys.get_state(blockchain2)
#     Process.sleep(5000)
#     Bitcoin.Node.sync(node2)
#     {_n, g2} = :sys.get_state(blockchain1)
#     Process.sleep(5000)
#     assert g1 != g2
#     assert length(g2) > length(g1)
#   end
# end
