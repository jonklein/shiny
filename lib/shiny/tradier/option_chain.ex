defmodule Shiny.Tradier.OptionChain do
  @moduledoc """
  Fetches option chain data from Tradier
  """

  def expirations(symbol) do
    {:ok, result} = Shiny.Tradier.get(expiration_url(symbol))
    (result.expirations && result.expirations.date) || []
  end

  def chain(symbol, expiration) do
    {:ok, result} = Shiny.Tradier.get(chain_url(symbol, expiration))
    result.options.option
  end

  defp expiration_url(symbol) do
    "/v1/markets/options/expirations?symbol=#{symbol}"
  end

  defp chain_url(symbol, expiration) do
    "/v1/markets/options/chains?symbol=#{symbol}&expiration=#{expiration}"
  end
end
