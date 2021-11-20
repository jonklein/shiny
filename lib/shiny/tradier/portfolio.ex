defmodule Shiny.Tradier.Portfolio do
  defstruct(profile: %{}, positions: [], balances: %{})

  @moduledoc """
  Fetches option position data from Tradier
  """

  def start_link() do
    Task.start_link(__MODULE__, :loop, [self()])
  end

  def loop(pid) do
    try do
      send(pid, {:portfolio, fetch()})
    rescue
      e ->
        IO.inspect("Error fetching portfolio: #{inspect(e)}")
    end

    Process.sleep(4000)

    loop(pid)
  end

  def fetch() do
    {:ok, profile} = Shiny.Tradier.get(profile_path())
    {:ok, balances} = Shiny.Tradier.get(balances_path(profile.profile.account.account_number))
    {:ok, positions} = positions(profile)

    %Shiny.Tradier.Portfolio{
      balances: balances.balances,
      positions: positions,
      profile: profile.profile
    }
  end

  defp positions(profile) do
    {:ok, positions} = Shiny.Tradier.get(positions_path(profile.profile.account.account_number))
    {:ok, adjust_positions(positions.positions)}
  end

  # Fix for tradier API returning bizarre data: if positions list
  # is empty, they give us the string "null".  If a single position,
  # they return it unwrapped (instead of a list with one position)

  defp adjust_positions("null") do
    []
  end

  defp adjust_positions(nil) do
    []
  end

  defp adjust_positions(%{position: nil}) do
    []
  end

  defp adjust_positions(%{position: position = %{}}) do
    [position]
  end

  defp adjust_positions(%{position: positions}) do
    positions
  end

  defp balances_path(account) do
    "/v1/accounts/#{account}/balances"
  end

  defp positions_path(account) do
    "/v1/accounts/#{account}/positions"
  end

  defp profile_path() do
    "/v1/user/profile"
  end
end
