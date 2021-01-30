defmodule Shiny.Strategy.Utils do
  def market_open?(date) do
    t = DateTime.to_time(date)
    Time.compare(t, ~T[09:30:00]) == :gt && Time.compare(t, ~T[16:00:00]) == :lt
  end
end
