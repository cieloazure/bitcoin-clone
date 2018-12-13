defmodule Bitcoin.Utilities.EventGenerator do
  alias Bitcoin.Structures.Block

  def broadcast_event(event_name, payload) do
    :inets.start()
    :ssl.start()
    HTTPoison.start()

    Enum.each(channels(), fn channel ->
      HTTPoison.post(channel, Poison.encode!(construct_event_data(event_name, payload)), [
        {"Content-Type", "application/json"}
      ])
    end)
  end

  defp construct_event_data(event_name, payload) do
    case event_name do
      "new_block_found" ->
        event_data =
          %{"event_name" => "new_block"}
          |> Map.put("height", Block.get_attr(payload, :height))
          |> Map.put("timestamp", Block.get_header_attr(payload, :timestamp))
          |> Map.put(
            "target",
            Block.get_header_attr(payload, :bits)
            |> Block.calculate_target_from_bits()
            |> Bitcoin.Utilities.Conversions.binary_to_decimal()
          )
          |> Map.put("reward", Block.get_attr(payload, :height) |> Block.get_block_value(0))
          |> Map.put("tx_count", Block.get_attr(payload, :tx_counter))
    end
  end

  defp channels do
    ["http://localhost:4000/event"]
  end
end
