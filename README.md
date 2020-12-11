# Shiny 

An algorithmic trading system written in Elixir, supporting basic backtesting and live execution (currently only via the Alpaca brokerage). 



## Getting Started

To get started, you'll need an Alpaca account, and the associated app and secret keys:

```
ALPACA_API_KEY=XXXXX
ALPACA_API_SECRET=XXXXX
```

To execute a backtest, use the `mix backtest` task along with a symbol and strategy:

```
mix backtest SPY Shiny.Strategy.MacdCross 30
```

## Strategies 

See the simple MacdCross strategy for an example:


```
defmodule Shiny.Strategy.MacdCross do
  # A simple demo strategy using an MACD cross.  Probably not a good idea for live trading.

  def execute(state, portfolio, symbol, bars) do
    current_bar = hd(bars)
    closes = Enum.map(bars, & &1.close) |> Enum.slice(0, 100)

    macd_histogram = TAlib.Indicators.MACD.histogram(closes)
    position = Shiny.Portfolio.position(portfolio, symbol)

    if position do
      if(macd_histogram < 0) do
        {state, %Shiny.Order{type: :close, symbol: symbol}}
      end
    else
      if(macd_histogram > 0) do
        {state, %Shiny.Order{type: :buy, symbol: symbol, shares: 100}}
      end
    end
  end
end
```


## Disclaimer

Disclaimer: All investments and trading in the stock market involve risk. Any decisions to place trades in the financial markets, including trading in stock or options or other financial instruments is a personal decision that should only be made after thorough research, including a personal risk and financial assessment and the engagement of professional assistance to the extent you believe necessary. The trading strategies or related information mentioned in this article is for informational purposes only.

