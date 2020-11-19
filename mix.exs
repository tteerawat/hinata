defmodule Hinata.MixProject do
  use Mix.Project

  @version "0.1.4"

  def project do
    [
      app: :hinata,
      version: @version,
      elixir: "~> 1.10",
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
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/teerawat1992/hinata"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bypass, "~> 2.0", only: :test},
      {:finch, "~> 0.4"},
      {:jason, "~> 1.0"}
    ]
  end
end
