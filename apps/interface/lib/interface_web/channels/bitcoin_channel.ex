defmodule InterfaceWeb.BitcoinChannel do
  use InterfaceWeb, :channel

  def join(channel_name, _params, socket) do
    {:ok, %{channel_name: channel_name}, socket}
  end

  def handle_in("message:test_msg", %{"message" => content}, socket) do
    broadcast!(socket, "bitcoin:test:new_message", %{content: content})
    {:reply, :ok, socket}
  end
end
