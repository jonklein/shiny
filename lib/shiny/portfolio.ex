defmodule Shiny.Portfolio do
  @moduledoc false

  require Logger

  defstruct cash: 0, positions: [], journal: []

  def order(portfolio, order = %{type: :buy}) do
    buy(portfolio, order.time, order.symbol, order.shares, order.limit)
  end

  def order(portfolio, order = %{type: :sell}) do
    sell(portfolio, order.time, order.symbol, order.shares, order.limit)
  end

  def order(portfolio, order = %{type: :close}) do
    close(portfolio, order.time, order.symbol, order.limit)
  end

  def buy(portfolio, time, symbol, shares, price) do
    price = slip(price, shares)

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

    journal = %{
      close: new_shares == 0,
      symbol: symbol,
      shares: shares,
      price: price,
      time: time,
      pnl: (price - position.cost_basis) * position.shares,
      cost_basis: position.cost_basis
    }

    %{
      portfolio
      | cash: portfolio.cash - price * shares,
        journal: portfolio.journal ++ [journal],
        positions:
          non_zero_positions(
            Enum.filter(portfolio.positions, &(&1.symbol != symbol)) ++ [new_position]
          )
    }
  end

  def sell(portfolio, time, symbol, shares, price) do
    buy(portfolio, time, symbol, -shares, price)
  end

  def close(portfolio, time, symbol, price) do
    position = position(portfolio, symbol)

    if(position) do
      sell(portfolio, time, symbol, position.shares, price)
    else
      portfolio
    end
  end

  def position(portfolio, symbol) do
    Enum.find(portfolio.positions, &(&1.symbol == symbol))
  end

  defp non_zero_positions(positions) do
    Enum.filter(positions, &(&1.shares != 0))
  end

  def report(portfolio) do
    closing_trades = Enum.filter(portfolio.journal, & &1.close)
    winning_trades = Enum.filter(closing_trades, &(&1.pnl > 0.0))
    losing_trades = Enum.filter(closing_trades, &(&1.pnl < 0.0))
    pnls = Enum.map(closing_trades, & &1.pnl)

    closing_trades |> IO.inspect()

    Logger.info("Portfolio cash: #{portfolio.cash}")
    Logger.info("Number of trades: #{length(portfolio.journal)}")
    Logger.info("Number of closing trades: #{length(closing_trades)}")
    Logger.info("Number of profitable closes: #{length(winning_trades)}")
    Logger.info("Number of losing closes: #{length(losing_trades)}")
    Logger.info("Win %: #{trunc(100 * length(winning_trades) / length(closing_trades))}")
    Logger.info("Avg PNL: #{Enum.sum(pnls) / length(closing_trades)}")
    Logger.info("Max win: #{Enum.max(pnls)}")
    Logger.info("Max loss: #{Enum.min(pnls)}")
    Logger.info("Total PNL: #{Enum.sum(pnls)}")
  end

  @slip 0.00

  def slip(price, shares) when shares < 0, do: price * (1.0 - @slip)
  def slip(price, shares), do: price * (1.0 + @slip)
end
