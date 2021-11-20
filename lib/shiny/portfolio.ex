defmodule Shiny.Portfolio do
  @moduledoc false

  require Logger

  defstruct cash: 0.0, positions: [], journal: [], slippage: 0.0

  def value(portfolio, quotes) do
    equity_value =
      portfolio.positions
      |> Enum.map(&(&1.shares * quotes[&1.symbol]))
      |> Enum.sum()

    portfolio.cash + equity_value
  end

  def order(portfolio, order = %{type: :buy}) do
    buy(portfolio, order.time, order.symbol, order.quantity, order.limit)
  end

  def order(portfolio, order = %{type: :sell}) do
    sell(portfolio, order.time, order.symbol, order.quantity, order.limit)
  end

  def order(portfolio, order = %{type: :close}) do
    close(portfolio, order.time, order.symbol, order.limit)
  end

  def order(portfolio, order = %{type: :target}) do
    target(portfolio, order.time, order.symbol, order.quantity, order.limit)
  end

  def buy(portfolio, _, _, 0, _) do
    portfolio
  end

  def buy(portfolio, time, symbol, shares, price) do
    price = slip(portfolio.slippage, price, shares)
    time = time || DateTime.utc_now()

    position = position(portfolio, symbol)

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

    report_trade(journal)

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

  def report_trade(journal = %{close: true}) do
    Logger.info(
      "#{Calendar.strftime(journal.time, "%c")}: #{journal.symbol} @ #{fmt(journal.price)} - close #{fmt(journal.shares)} (pnl #{fmt(journal.pnl)})"
    )
  end

  def report_trade(journal) do
    Logger.info(
      "#{Calendar.strftime(journal.time, "%c")}: #{journal.symbol} @ #{fmt(journal.price)} - open  #{fmt(journal.shares)}"
    )
  end

  def sell(portfolio, time, symbol, shares, price) do
    buy(portfolio, time, symbol, -shares, price)
  end

  def target(portfolio, time, symbol, shares, price) do
    position = position(portfolio, symbol)
    buy(portfolio, time, symbol, shares - position.shares, price)
  end

  def close(portfolio, time, symbol, price) do
    target(portfolio, time, symbol, 0, price)
  end

  def position(portfolio, symbol) do
    Enum.find(portfolio.positions, &(&1.symbol == symbol)) ||
      %{symbol: symbol, shares: 0, cost_basis: 0}
  end

  defp non_zero_positions(positions) do
    Enum.filter(positions, &(&1.shares != 0))
  end

  def report(portfolio) do
    closing_trades = Enum.filter(portfolio.journal, & &1.close)
    winning_trades = Enum.filter(closing_trades, &(&1.pnl > 0.0))
    losing_trades = Enum.filter(closing_trades, &(&1.pnl < 0.0))
    pnls = Enum.map(closing_trades, & &1.pnl)
    max_count = max(1, length(closing_trades))

    max = &((&1 == [] && 0) || Enum.max(&1))
    min = &((&1 == [] && 0) || Enum.min(&1))

    [
      cash: fmt(portfolio.cash),
      win_percent: fmt(100 * length(winning_trades) / max_count),
      number_of_trades: length(portfolio.journal),
      number_of_closing_trades: length(closing_trades),
      number_of_profitable_closes: length(winning_trades),
      number_of_losing_closes: length(losing_trades),
      average_pnl: fmt(Enum.sum(pnls) / max_count),
      max_win: fmt(max.(pnls)),
      max_loss: fmt(min.(pnls)),
      total_pnl: fmt(Enum.sum(pnls))
    ]
  end

  defp slip(slippage, price, shares) when shares < 0, do: price * (1.0 - slippage / 100.0)
  defp slip(slippage, price, _), do: price * (1.0 + slippage / 100.0)

  defp fmt(d), do: ExPrintf.sprintf("%.2f", [d * 1.0])
end
