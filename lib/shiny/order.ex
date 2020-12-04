defmodule Shiny.Order do
  @defmodule """
  Defines an order output of a strategy.

  `type` is one of :buy, :sell or :close
  """

  defstruct(symbol: "", shares: 0, limit: 0, type: :none, time: nil)
end
