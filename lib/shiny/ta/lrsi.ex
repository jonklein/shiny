defmodule Breaker.Ta.LRSI do
  @doc """
  Laguerre RSI
  """
  @spec lrsi([float, ...]) :: {float, float, float, float, float}

  def lrsi([]) do
    {0, 0, 0, 0, 0.0}
  end

  def lrsi([price]) do
    {price, price, price, price, 0.0}
  end

  def lrsi([price | rest]) do
    alpha = 0.7

    {_, prevL0, prevL1, prevL2, prevL3} = lrsi(rest)

    source = price
    gamma = 1.0 - alpha

    l0 = (1 - gamma) * source + gamma * prevL0
    l1 = -gamma * l0 + prevL0 + gamma * prevL1
    l2 = -gamma * l1 + prevL1 + gamma * prevL2
    l3 = -gamma * l2 + prevL2 + gamma * prevL3

    cu = ((l0 > l1 && l0 - l1) || 0) + ((l1 > l2 && l1 - l2) || 0) + ((l2 > l3 && l2 - l3) || 0)
    cd = ((l0 < l1 && l1 - l0) || 0) + ((l1 < l2 && l2 - l1) || 0) + ((l2 < l3 && l3 - l2) || 0)

    rsi = if cu + cd != 0.0, do: cu / (cu + cd), else: 0

    {rsi, l0, l1, l2, l3}
  end
end
