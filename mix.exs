defmodule Hinata.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :hinata,
      version: @version,
      elixir: "~> 1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Hinata.Application, []}
    ]
  end

  defp description do
    "An HTTP client for JSON API."
  end

  defp package do
    [
      files: ~w(lib priv .formatter.exs mix.exs README*)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bypass, "~> 1.0", only: :test},
      {:finch, "~> 0.4"},
      {:jason, "~> 1.0"}
    ]
  end
end
