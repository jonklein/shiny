defmodule Shiny.Tradier.QuoteStreamer do
  @moduledoc """
  Streams market data from Tradier.

  Note: unlike other Tradier calls, streaming requires a production key
  """

  use WebSockex
  require Logger

  def start_link(symbols: symbols, callback: callback_pid) do
    {:ok, response} = HTTPoison.post(session_url(), "", headers())
    %{stream: %{url: url, sessionid: sessionID}} = Jason.decode!(response.body, keys: :atoms)
    url |> IO.inspect()

    {:ok, debouncer} = Shiny.Debouncer.start_link(&send(callback_pid, {:quotes, &1}), 1500)

    {:ok, pid} =
      WebSockex.start_link(
        stream_url(),
        __MODULE__,
        %{
          session_id: sessionID,
          quotes: %{},
          symbols: [],
          debouncer: debouncer
        },
        name: __MODULE__
      )

    set_symbols(symbols)
    {:ok, pid}
  end

  def terminate(reason, _) do
    Logger.info("Tradier socket terminating: #{inspect(reason)}")
    exit(:kill)
  end

  def set_symbols(symbols) do
    WebSockex.cast(__MODULE__, {:set_symbols, symbols})
  end

  def handle_cast({:set_symbols, symbols}, state = %{symbols: current_symbols})
      when symbols == current_symbols do
    {:ok, state}
  end

  def handle_cast({:set_symbols, symbols}, state) do
    Logger.info("Listening for symbols: #{Enum.join(symbols, ", ")}")
    {:reply, {:text, listen(symbols, state.session_id)}, %{state | quotes: %{}, symbols: symbols}}
  end

  def handle_info(other, state) do
    Logger.info("Unknown info: #{inspect(other)}")
    {:ok, state}
  end

  def handle_connect(info, state) do
    Logger.info("Tradier socket connected: #{info}")
    {:ok, state}
  end

  defp listen(symbols, sessionID) do
    Jason.encode!(%{
      symbols: symbols,
      advancedDetails: false,
      sessionid: sessionID,
      linebreak: true
    })
  end

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

  def handle_frame(frame, _) do
    IO.inspect("Unknown frame: #{inspect(frame)}")
  end

  defp update_quotes(quotes, message = %{type: "quote", symbol: symbol}) do
    update_symbol(
      quotes,
      symbol,
      %{
        bid: float(message[:bid]),
        ask: float(message[:ask]),
        date: parse_date(message[:askdate])
      }
    )
  end

  defp update_quotes(quotes, message = %{type: "summary", symbol: symbol}) do
    update_symbol(
      quotes,
      symbol,
      %{
        open: float(message[:open]),
        previous_close: float(message[:prevClose])
      }
    )
  end

  defp update_quotes(quotes, message = %{type: "trade", symbol: symbol}) do
    message |> IO.inspect()

    update_symbol(
      quotes,
      symbol,
      update_last(
        Map.get(quotes, symbol, %{}),
        float(message[:price]),
        parse_date(message[:date]),
        integer(message[:cumulative_volume])
      )
    )
  end

  defp update_quotes(quotes, message = %{type: "timesale", symbol: symbol}) do
    message |> IO.inspect()

    update_symbol(
      quotes,
      symbol,
      update_last(
        Map.get(quotes, symbol, %{}),
        float(message[:last]),
        parse_date(message[:date]),
        nil
      )
    )
  end

  defp update_quotes(quotes, message) do
    Logger.info("Unknown message: #{inspect(message)}")
    quotes
  end

  defp update_last(data, price, time, volume) do
    if(!Map.get(data, :time) || DateTime.compare(time, Map.get(data, :time)) == :gt) do
      Map.merge(data, %{
        volume: volume,
        last: price,
        change: price - Map.get(data, :previous_close, price),
        time: time
      })
    else
      data
    end
  end

  defp update_symbol(quotes, symbol, update) do
    data = Map.get(quotes, symbol, %{})
    Map.merge(quotes, %{symbol => Map.merge(data, update)})
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

  defp integer(i) when is_binary(i) do
    case Integer.parse(i) do
      {n, _} -> n
      :error -> 0.0
    end
  end

  defp integer(i) do
    i
  end

  defp headers do
    token = System.get_env("TRADIER_ACCESS_TOKEN")

    [
      Authorization: "Bearer #{token}",
      Accept: "application/json"
    ]
  end

  defp stream_url() do
    "wss://ws.tradier.com/v1/markets/events"
  end

  defp session_url() do
    "https://api.tradier.com/v1/markets/events/session"
  end

  defp parse_date(d) do
    {:ok, date} = DateTime.from_unix(trunc(integer(d) / 1000.0))
    date
  end
end
