defmodule Shiny do
  def start(_, _args) do
    Shiny.Executor.start_link("SPY", Shiny.Strategy.GapFade)
  end
end
