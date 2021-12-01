defmodule Shiny.MixProject do
  use Mix.Project

  def project do
    [
      app: :shiny,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssl]
    ]
  end

  defp deps do
    [
      {:websockex, "~> 0.4.3"},
      {:exprintf, "~> 0.2.1"},
      {:hackney, "~> 1.17.0"},
      {:jason, "~> 1.2"},
      {:timex, "~> 3.6"},
      {:csv, "~> 2.4"},
      {:httpoison, "~> 1.8.0"},
      {:tzdata, "~> 1.0.5"},
      {:talib, "~> 0.3.6"}
    ]
  end
end
