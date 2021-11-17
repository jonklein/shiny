defmodule Shiny.Strategy do
  def from_config(config) do
    strategy = resolve_strategy(config.strategy)

    state =
      if Kernel.function_exported?(strategy, :init, 1) do
        strategy.init(config.params)
      else
        config.params
      end

    symbols = [config.params.symbol]

    {strategy, state, symbols}
  end

  defp resolve_strategy(strategy) do
    {module, _} = Code.eval_string(strategy)
    Code.ensure_loaded(module)
    module
  end
end
