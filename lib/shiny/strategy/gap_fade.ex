defmodule Shiny.Strategy.GapFade do
  @moduledoc false

  def execute(bars) do
    IO.inspect(Enum.at(bars, 0))
  end
end
