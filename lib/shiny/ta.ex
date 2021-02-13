defmodule Shiny.Ta do
  @doc """
  Laguerre RSI
  """
  @spec lrsi([%{}, ...]) :: float
  def lrsi(bars) do
    {value, _, _, _, _} = Shiny.Ta.LRSI.lrsi(bars)
    value
  end
end
