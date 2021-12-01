defmodule Shiny.Broker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{portfolios: %{}, portfolio: %Shiny.Portfolio{cash: 10000}}}
  end

  def module(broker, module) do
    broker_mod =
      case broker do
        "FTX" -> Shiny.FTX
        "Polygon" -> Shiny.Polygon
        _ -> Shiny.Tradier
      end

    Module.concat(broker_mod, module)
  end

  def portfolio(id) do
    GenServer.call(__MODULE__, {:portfolio, id})
  end

  def create_account(id, cash) do
    GenServer.cast(__MODULE__, {:create_account, id, cash})
  end

  def order(id, order) do
    GenServer.cast(__MODULE__, {:order, id, order})
  end

  def handle_call({:portfolio, id}, _, state) do
    {:reply, state.portfolios[id], state}
  end

  def handle_cast({:order, id, order}, state) do
    {:noreply,
     %{portfolios: %{state.portfolios | id => Shiny.Portfolio.order(state.portfolios[id], order)}}}
  end

  def handle_cast({:create_account, id, cash}, state) do
    {:noreply, %{portfolios: Map.merge(state.portfolios, %{id => %Shiny.Portfolio{cash: cash}})}}
  end
end
