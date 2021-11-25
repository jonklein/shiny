defmodule Shiny.Order do
  @moduledoc """
  Defines an order output of a strategy.

  `type` is one of :buy, :sell or :close
  """

  defstruct(
    symbol: "",
    quantity: 0,
    id: nil,
    limit: 0,
    price: 0.0,
    fill: nil,
    type: :none,
    time: nil
  )
end
