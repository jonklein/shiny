defmodule Shiny.Portfolio do
  @moduledoc false

  defstruct cash: 0, positions: [], journal: []

  def order(portfolio, order = %{type: :buy}) do
    buy(portfolio, order.symbol, order.shares, order.limit)
  end

  def order(portfolio, order = %{type: :sell}) do
    sell(portfolio, order.symbol, order.shares, order.limit)
  end

  def order(portfolio, order = %{type: :close}) do
    close(portfolio, order.symbol, order.limit)
  end

  def buy(portfolio, symbol, shares, price) do
    position = position(portfolio, symbol) || %{symbol: symbol, shares: 0, cost_basis: 0}

    new_shares = position.shares + shares

    new_position = %{
      position
      | shares: shares + position.shares,
        cost_basis:
          if(new_shares != 0,
            do:
              (position.shares * position.cost_basis + shares * price) /
                new_shares,
            else: 0
          )
    }

    if new_position.shares == 0 do
      IO.inspect(
        "Closing trade from #{position.shares * position.cost_basis} to #{position.shares * price} (#{
          position.shares * price - position.shares * position.cost_basis
        })"
      )
    end

    %{
      portfolio
      | cash: portfolio.cash - price * shares,
        positions:
          non_zero_positions(
            Enum.filter(portfolio.positions, &(&1.symbol != symbol)) ++ [new_position]
          )
    }
  end

  def sell(portfolio, symbol, shares, price) do
    buy(portfolio, symbol, -shares, price)
  end

  def close(portfolio, symbol, price) do
    position = position(portfolio, symbol)
    sell(portfolio, symbol, position.shares, price)
  end

  def position(portfolio, symbol) do
    Enum.find(portfolio.positions, &(&1.symbol == symbol))
  end

  defp non_zero_positions(positions) do
    Enum.filter(positions, &(&1.shares != 0))
  end
end
