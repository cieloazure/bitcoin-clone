defmodule InterfaceWeb.SimulationController do
  use InterfaceWeb, :controller
  require Logger

  plug(:put_layout, "simulation_layout.html")

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def handle_event(conn, params) do
    # InterfaceWeb.Endpoint.broadcast("bitcoin:test", "bitcoin:test:new_message", %{content: "hello from controller"})
    case Map.get(params, "event_name") do
      "new_block" ->
        InterfaceWeb.Endpoint.broadcast("bitcoin:simulation", "bitcoin:simulation:new_block", %{
          height: Map.get(params, "height"),
          target: Map.get(params, "target"),
          timestamp: Map.get(params, "timestamp"),
          reward: Map.get(params, "reward"),
          tx_count: Map.get(params, "tx_count")
        })
    end

    json(conn, %{"status" => "ok"})
  end
end
