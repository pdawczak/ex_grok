defmodule ExGrok.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_grok,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger],
     mod: {ExGrok.Application, []}]
  end

  defp deps do
    []
  end
end
