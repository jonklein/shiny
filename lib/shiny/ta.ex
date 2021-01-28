defmodule Breaker.Ta do
  @doc """
  Laguerre RSI
  """
  @spec lrsi([%{}, ...]) :: float
  def lrsi(bars) do
    {value, _, _, _, _} = Breaker.Ta.LRSI.lrsi(bars)
    value
  end
end
