defmodule Shiny.BrokerTest do
  use ExUnit.Case
  doctest Shiny.Portfolio

  setup do
    {:ok, _} = start_supervised(Shiny.Broker)
    Shiny.Broker.create_account("default", 1000)
    :ok
  end

  test "handles orders" do
    Shiny.Broker.order(
      "default",
      %Shiny.Order{symbol: "SPY", limit: 400, quantity: 1.0, type: :buy}
    )

    Shiny.Broker.order(
      "default",
      %Shiny.Order{symbol: "QQQ", limit: 200, quantity: 2.0, type: :buy}
    )

    Shiny.Broker.order(
      "default",
      %Shiny.Order{symbol: "QQQ", limit: 250, quantity: 1.0, type: :sell}
    )

    portfolio = Shiny.Broker.portfolio("default")
    assert portfolio.cash == 450

    assert portfolio.positions == [
             %{symbol: "SPY", shares: 1, cost_basis: 400},
             %{symbol: "QQQ", shares: 1, cost_basis: 150}
           ]
  end
end
