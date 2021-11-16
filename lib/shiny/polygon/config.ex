defmodule Shiny.Config do
  @derive Jason.Encoder
  defstruct symbols: [],
            timeframe: "5min",
            strategy: "",
            portfolio: %{},
            params: %{}

  def from_file!(file) do
    struct(%Shiny.Config{}, Jason.decode!(File.read!(file), keys: :atoms))
  end

  def put_param(config, key, value) do
    put_in(config.params[key], replace(config.params[key], value))
  end

  defp replace(old_value, new_value) when is_integer(old_value) do
    elem(Integer.parse(new_value), 0)
  end

  defp replace(old_value, new_value) when is_float(old_value) do
    elem(Float.parse(new_value), 0)
  end
end
