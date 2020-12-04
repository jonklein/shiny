defmodule ShinyPortfoiloTest do
  use ExUnit.Case
  doctest Shiny.Portfolio

  test "buys" do
    portfolio = %Shiny.Portfolio{cash: 1000}
    portfolio = Shiny.Portfolio.buy(portfolio, DateTime.utc_now(), "SPY", 1, 400)
    assert portfolio.cash == 600
    assert portfolio.positions == [%{symbol: "SPY", shares: 1, cost_basis: 400}]

    portfolio = Shiny.Portfolio.buy(portfolio, DateTime.utc_now(), "QQQ", 2, 200)
    assert portfolio.cash == 200

    assert portfolio.positions == [
             %{symbol: "SPY", shares: 1, cost_basis: 400},
             %{symbol: "QQQ", shares: 2, cost_basis: 200}
           ]
  end

  test "sells" do
    portfolio = %Shiny.Portfolio{cash: 1000}
    portfolio = Shiny.Portfolio.buy(portfolio, DateTime.utc_now(), "SPY", 1, 400)
    portfolio = Shiny.Portfolio.buy(portfolio, DateTime.utc_now(), "QQQ", 2, 200)
    portfolio = Shiny.Portfolio.sell(portfolio, DateTime.utc_now(), "QQQ", 1, 250)

    assert portfolio.cash == 450

    assert portfolio.positions == [
             %{symbol: "SPY", shares: 1, cost_basis: 400},
             %{symbol: "QQQ", shares: 1, cost_basis: 150}
           ]
  end

  test "closes" do
    portfolio = %Shiny.Portfolio{cash: 1000}
    portfolio = Shiny.Portfolio.buy(portfolio, DateTime.utc_now(), "SPY", 1, 400)
    portfolio = Shiny.Portfolio.buy(portfolio, DateTime.utc_now(), "QQQ", 2, 200)
    portfolio = Shiny.Portfolio.close(portfolio, DateTime.utc_now(), "QQQ", 190)

    assert portfolio.cash == 580
    assert portfolio.positions == [%{symbol: "SPY", shares: 1, cost_basis: 400}]
  end
end
