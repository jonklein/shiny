defmodule Shiny.Alpaca.QuoteStreamer do
  use WebSockex
  require Logger

  def url() do
    "wss://socket.polygon.io/stocks"
  end

  def start_link(symbols) do
    {:ok, pid} = WebSockex.start_link(url(), __MODULE__, %{})
    WebSockex.send_frame(pid, {:text, auth()})
    WebSockex.send_frame(pid, {:text, listen()})
    {:ok, pid}
  end

  defp auth() do
    Jason.encode!(%{action: "auth", params: System.get_env("ALPACA_API_KEY")})
  end

  defp listen() do
    Jason.encode!(%{action: "subscribe", params: "Q.SPY,A.SPY"})
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
