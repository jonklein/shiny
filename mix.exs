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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Shiny, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:websockex, "~> 0.4.2"},
      {:hackney, "~> 1.16.0"},
      {:jason, "~> 1.2"},
      {:httpoison, "~> 1.7.0"},
      {:tzdata, "~> 1.0.5"},
      {:talib, "~> 0.3.6"},
      {:niex, path: "../niex"}
    ]
  end
end
