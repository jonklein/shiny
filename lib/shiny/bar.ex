defmodule Shiny.Bar do
  @defmodule """
  A price bar.
  Contains entries for open, high, low, close & volume
  """

  @type t :: %__MODULE__{
          open: float,
          high: float,
          low: float,
          close: float,
          volume: integer,
          partial: boolean
        }

  defstruct(
    open: 0,
    high: 0,
    low: 0,
    close: 0,
    time: 0,
    volume: 0,
    partial: false
  )
end
