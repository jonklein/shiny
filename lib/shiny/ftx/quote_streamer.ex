defmodule Shiny.FTX.QuoteStreamer do
  @moduledoc """
  Streams market data from FTX.
  """

  use WebSockex
  require Logger

  def start_link(symbols, callback_pid) do
    {:ok, debouncer} =
      Shiny.Debouncer.start_link(
        fn quotes ->
          send(callback_pid, {:quotes, quotes})
        end,
        500
      )

    {:ok, pid} =
      WebSockex.start_link(
        stream_url(),
        __MODULE__,
        %{
          quotes: %{},
          symbols: [],
          debouncer: debouncer
        },
        name: __MODULE__
      )

    login()
    set_symbols(symbols)
    {:ok, pid}
  end

  def login() do
    WebSockex.cast(__MODULE__, {:login})
  end

  def terminate(reason, state) do
    Logger.info("FTX socket terminating:\n#{inspect(reason)}\n\n#{inspect(state)}\n")
    exit(:kill)
  end

  def set_symbols(symbols) do
    symbols
    |> Enum.map(fn symbol -> WebSockex.cast(__MODULE__, {:subscribe, symbol}) end)
  end

  # TODO: monitor processes to unsubscribe from symbols
  #  def handle_info({:DOWN, _, :process, pid, :normal}, state) do
  #    IO.inspect("Got down from #{inspect(pid)} - unsubscribing")
  #    {:ok, state}
  #  end

  def handle_cast({:login}, state) do
    {:reply, {:text, login_message()}, state}
  end

  def handle_cast({:subscribe, symbol}, state) do
    symbols = [symbol | state.symbols] |> Enum.uniq()

    if !Enum.find(state.symbols, &(&1 == symbol)) do
      {:reply, {:text, subscribe_message(symbol)}, %{state | quotes: %{}, symbols: symbols}}
    else
      {:ok, state}
    end
  end

  defp timestamp() do
    (DateTime.utc_now() |> DateTime.to_unix()) * 1000
  end

  def signature(timestamp, secret \\ System.get_env("FTX_API_SECRET")) do
    :crypto.mac(
      :hmac,
      :sha256,
      secret,
      Integer.to_string(timestamp) <> "websocket_login"
    )
    |> Base.encode16()
    |> String.downcase()
  end

  defp login_message() do
    ts = timestamp()

    Jason.encode!(%{
      op: "login",
      args: %{key: System.get_env("FTX_API_KEY"), sign: signature(ts), time: ts}
    })
  end

  defp subscribe_message(symbol) do
    Jason.encode!(%{
      channel: "ticker",
      market: symbol,
      op: "subscribe"
    })
  end

  #  defp unsubscribe_message(symbol) do
  #    Jason.encode!(%{
  #      channel: "ticker",
  #      market: symbol,
  #      op: "unsubscribe"
  #    })
  #  end

  def handle_frame({:text, msg}, state) do
    quotes =
      try do
        update_quotes(state.quotes, Jason.decode!(msg, keys: :atoms))
      rescue
        err ->
          IO.inspect(err)
          state.quotes
      end

    Shiny.Debouncer.call(state.debouncer, [quotes])

    {:ok, %{state | quotes: quotes}}
  end

  defp update_quotes(
         quotes,
         %{channel: "ticker", market: symbol, type: "subscribed"}
       ) do
    Logger.info("Successully subscribed to #{symbol}")
    quotes
  end

  defp update_quotes(
         quotes,
         %{channel: "ticker", market: symbol, type: "update", data: data}
       ) do
    update_symbol(
      quotes,
      symbol,
      %{
        bid: float(data.bid),
        ask: float(data.ask),
        last: float(data.last),
        time: parse_date(data.time)
      }
    )
  end

  defp update_quotes(quotes, message) do
    Logger.info("Unknown message: #{inspect(message)}")
    quotes
  end

  defp update_symbol(quotes, symbol, update) do
    data = Map.get(quotes, symbol, %{})
    Map.merge(quotes, %{symbol => Map.merge(data, update)})
  end

  defp integer(i) when is_binary(i) do
    case Integer.parse(i) do
      {n, _} -> n
      :error -> 0.0
    end
  end

  defp integer(i) do
    i
  end

  defp float(i) when is_binary(i) do
    case Float.parse(i) do
      {n, _} -> n
      :error -> 0.0
    end
  end

  defp float(i) do
    i
  end

  defp parse_date(d) do
    {:ok, date} = DateTime.from_unix(trunc(integer(d)))
    date
  end

  defp stream_url() do
    "wss://ftx.us/ws"
  end
end
