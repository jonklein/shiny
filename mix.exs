defmodule Shiny.MixProject do
  use Mix.Project

  def project do
    [
      app: :shiny,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:websockex, "~> 0.4.2"},
      {:hackney, "~> 1.16.0"},
      {:jason, "~> 1.2"},
      {:csv, "~> 2.4"},
      {:httpoison, "~> 1.7.0"},
      {:tzdata, "~> 1.0.5"},
      {:talib, "~> 0.3.6"},
      {:niex, git: "https://github.com/jonklein/niex"}
    ]
  end
end
