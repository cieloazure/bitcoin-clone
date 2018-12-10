defmodule Bitcoin.Utilities.EventGenerator do
  alias Bitcoin.Structures.Block

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
      "new_block_found" -> 
        event_data = %{"event_name" => "new_block"}
        event_data = Map.put(event_data, "height", Block.get_attr(payload, :height))
        event_data = Map.put(event_data, "timestamp", Block.get_header_attr(payload, :timestamp))
        event_data = Map.put(event_data, "bits", Block.get_header_attr(payload, :bits))
      #"new_transaction" -> Map.from_struct(payload)  |> Map.take([:tx_id])
    end
  end

  defp channels do
    ["http://localhost:4000/event"]
  end
end
