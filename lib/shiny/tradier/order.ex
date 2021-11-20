defmodule Shiny.Tradier.Order do
  def create(%Shiny.Tradier.Portfolio{} = portfolio, %Shiny.Order{} = order) do
    Shiny.Tradier.post(
      path(portfolio.profile.account),
      format_order(order)
    )
  end

  def update(%Shiny.Tradier.Portfolio{} = portfolio, %Shiny.Order{} = order) do
    Shiny.Tradier.put(
      path(portfolio.profile.account, order),
      Map.take(format_order(order), [:price])
    )
  end

  def delete(%Shiny.Tradier.Portfolio{} = portfolio, %Shiny.Order{} = order) do
    Shiny.Tradier.delete(path(portfolio.profile.account, order))
  end

  def list(%Shiny.Tradier.Portfolio{} = portfolio) do
    {:ok, response} = Shiny.Tradier.get(path(portfolio.profile.account))
    {:ok, process_orders(response)}
  end

  def process_orders(%{orders: %{order: nil}}) do
    []
  end

  def process_orders(%{orders: %{order: order = %{}}}) do
    [order]
  end

  def process_orders(%{orders: %{order: orders}}) do
    orders
  end

  def path(account) do
    "/v1/accounts/#{account.account_number}/orders"
  end

  def path(account, order) do
    "/v1/accounts/#{account.account_number}/orders/#{order.id}"
  end

  defp format_order(order) do
    Map.merge(
      Map.from_struct(order),
      %{
        class: order_class(order),
        option_symbol: option_symbol?(order.symbol) && order.symbol,
        symbol: !option_symbol?(order.symbol) && order.symbol,
        price: ExPrintf.sprintf("%.2f", [order.price]),
        quantity: abs(order.quantity),
        duration: "day",
        preview: false,
        type: "limit",
        side: side(order)
      }
    )
    |> IO.inspect()
  end

  defp side(order) when order.quantity > 0 do
    (option_symbol?(order.symbol) && "buy_to_open") || "buy"
  end

  defp side(order) when order.quantity < 0 do
    (option_symbol?(order.symbol) && "sell_to_close") || "sell"
  end

  defp order_class(%{symbol: symbol}) do
    (option_symbol?(symbol) && "option") || "equity"
  end

  defp option_symbol?(symbol) do
    String.match?(symbol, ~r"([\w]+)((\d{2})(\d{2})(\d{2}))([PC])(\d{8})")
  end
end
