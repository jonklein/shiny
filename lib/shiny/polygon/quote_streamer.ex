defmodule Shiny.Polygon.QuoteStreamer do
  @moduledoc """
  Streams market data from Polygon.  Requires the environment variables `ALPACA_API_KEY` and `ALPACA_API_SECRET` to be set.
  """

  use WebSockex
  require Logger

  def url() do
    "wss://socket.polygon.io/stocks"
  end

  def start_link(symbols, callback) do
    {:ok, pid} = WebSockex.start_link(url(), __MODULE__, %{callback: callback, symbols: symbols})
    WebSockex.send_frame(pid, {:text, auth()})
    WebSockex.send_frame(pid, {:text, listen()})
    {:ok, pid}
  end

  defp auth() do
    api_key = System.get_env("POLYGON_API_KEY")
    Jason.encode!(%{action: "auth", params: api_key})
  end

  defp listen() do
    Jason.encode!(%{action: "subscribe", params: "SPY"})
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected!")
    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    Logger.info("Received Message - Type: #{inspect(type)} -- Message: #{msg}")
    {:ok, state}
  end
end
