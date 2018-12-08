defmodule InterfaceWeb.SimulationController do
  use InterfaceWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def handle_event(conn, params) do
    InterfaceWeb.Endpoint.broadcast("bitcoin:test", "bitcoin:test:new_message", %{content: "hello from controller"})
    json(conn, %{"status" => "ok"})
  end
end
