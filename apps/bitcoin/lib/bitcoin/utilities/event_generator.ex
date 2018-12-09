defmodule Bitcoin.Utilities.EventGenerator do
  def broadcast_event(event_name, payload) do
    :inets.start
    :ssl.start
    HTTPoison.start()
    Enum.each(channels(), fn channel -> 
      HTTPoison.post(channel, Poison.encode!(construct_event_data(event_name, payload)), [{"Content-Type", "application/json"}])
    end)
  end

  defp construct_event_data(event_name, payload) do
    case event_name do
      "new_block_found" -> Map.from_struct(payload)  |> Map.take([:height])
      "new_transaction" -> Map.from_struct(payload)  |> Map.take([:tx_id])
    end
  end

  defp channels do
    ["http://localhost:4000/event"]
  end
end
