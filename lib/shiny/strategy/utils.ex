defmodule Shiny.Strategy.Utils do
  @doc """
  Indicates whether the provided DateTime is during the normal US market open times.

  Note: the provided date is considered to be the starting time of a
  period such that 09:30ET is considered "open", while 16:00ET is considered closed.
  """
  @spec market_open?(%DateTime{}) :: boolean
  def market_open?(d = %DateTime{}) do
    # way faster than converting to Time and using Time.compare:
    t = d.hour * 60 + d.minute
    t < 16 * 60 && t >= 9 * 60 + 30
  end

  @spec to_market_timezone(%DateTime{}) :: %DateTime{}
  def to_market_timezone(d = %DateTime{}) do
    Timex.Timezone.convert(d, "America/New_York")
  end

  @doc """
  Indicates whether the provided DateTimes have the same date.
  """
  @spec same_day?(%DateTime{}, %DateTime{}) :: boolean
  def same_day?(d1, d2) do
    d1.day == d2.day && d1.month == d2.month && d1.year == d2.year
  end
end
