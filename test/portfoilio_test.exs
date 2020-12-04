defmodule ShinyPortfoiloTest do
  use ExUnit.Case
  doctest Shiny.Portfolio

  test "buys" do
    portfolio = %Shiny.Portfolio{cash: 1000}
    portfolio = Shiny.Portfolio.buy(portfolio, "SPY", 1, 400)
    assert portfolio.cash == 600
    assert portfolio.positions == [%{symbol: "SPY", shares: 1}]

    portfolio = Shiny.Portfolio.buy(portfolio, "QQQ", 2, 200)
    assert portfolio.cash == 200
    assert portfolio.positions == [%{symbol: "SPY", shares: 1}, %{symbol: "QQQ", shares: 2}]
  end

  test "sells" do
    portfolio = %Shiny.Portfolio{cash: 1000}
    portfolio = Shiny.Portfolio.buy(portfolio, "SPY", 1, 400)
    portfolio = Shiny.Portfolio.buy(portfolio, "QQQ", 2, 200)
    portfolio = Shiny.Portfolio.sell(portfolio, "QQQ", 1, 250)

    assert portfolio.cash == 450
    assert portfolio.positions == [%{symbol: "SPY", shares: 1}, %{symbol: "QQQ", shares: 1}]
  end

  test "closes" do
    portfolio = %Shiny.Portfolio{cash: 1000}
    portfolio = Shiny.Portfolio.buy(portfolio, "SPY", 1, 400)
    portfolio = Shiny.Portfolio.buy(portfolio, "QQQ", 2, 200)
    portfolio = Shiny.Portfolio.close(portfolio, "QQQ", 190)

    assert portfolio.cash == 580
    assert portfolio.positions == [%{symbol: "SPY", shares: 1}]
  end
end
