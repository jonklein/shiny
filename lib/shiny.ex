defmodule Shiny do
  def run() do
    Shiny.Alpaca.Executor.start_link("SPY", Shiny.Strategy.GapFade)
  end
end
