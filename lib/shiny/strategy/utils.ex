defmodule Shiny.Strategy.Utils do
  @doc """
  Indicates whether the provided DateTime is during the normal US market open times.

  Note: the provided date is considered to be the starting time of a
  period such that 09:30ET is considered "open", while 16:00ET is considered closed.
  """
  @spec market_open?(%DateTime{}) :: boolean
  def market_open?(d = %DateTime{}) do
    t = DateTime.to_time(to_market_timezone(d))
    Time.compare(t, ~T[09:30:00]) == :gt && Time.compare(t, ~T[16:00:00]) == :lt
  end

  @spec to_market_timezone(%DateTime{}) :: %DateTime{}
  def to_market_timezone(d = %DateTime{}) do
    Timex.Timezone.convert(d, "America/New_York")
  end
end
