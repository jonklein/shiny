defmodule Shiny.Config do
  @derive Jason.Encoder
  defstruct symbols: [],
            timeframe: "5min",
            strategy: "",
            data_broker: "",
            execution_broker: "",
            portfolio: %{},
            params: %{}

  def from_file!(file) do
    struct(%Shiny.Config{}, Jason.decode!(File.read!(file), keys: :atoms))
  end

  def put_param(config, key, value) do
    put_in(config.params[key], replacement(config.params[key], value))
  end

  defp replacement(old_value, new_value) when is_integer(old_value) do
    elem(Integer.parse(new_value), 0)
  end

  defp replacement(old_value, new_value) when is_float(old_value) do
    elem(Float.parse(new_value), 0)
  end

  defp replacement(_, new_value) do
    new_value
  end
end
