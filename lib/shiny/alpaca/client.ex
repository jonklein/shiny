defmodule Shiny.Alpaca.Client do
  @moduledoc """
  Brokerage API connector for Alpaca.  Requires the environment variables `ALPACA_API_KEY` and `ALPACA_API_SECRET` to be set.
  """

  def request(path) do
    response =
      HTTPoison.get!(url(path),
        "APCA-API-KEY-ID": System.get_env("ALPACA_API_KEY"),
        "APCA-API-SECRET-KEY": System.get_env("ALPACA_API_SECRET")
      )

    Jason.decode!(response.body)
  end

  def positions() do
    request("/v2/positions")
  end

  def account() do
    request("/v2/account")
  end

  defp url(path) do
    System.get_env("ALPACA_ENDPOINT") <> path
  end
end
