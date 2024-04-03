defmodule Icaecrawler.MixProject do
  use Mix.Project

  def project do
    [
      app: :icaecrawler,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Icaecrawler.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.33.0"},
      {:req, "~> 0.4.0"},
      {:poison, "~> 5.0.0"},
      {:nimble_csv, "~> 1.2.0"}
    ]
  end

  def releases do
    [
      demo: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  end
end
