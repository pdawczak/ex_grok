defmodule ExGrok.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_grok,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(),
     aliases: aliases(),
     name: "ExGrok",
     source_url: "https://github.com/pdawczak/ex_grok",
     homepage_url: "https://github.com/pdawczak/ex_grok",
     docs: [main: "readme",
            extras: ["README.md"]]]
  end

  def application do
    [applications: [:logger],
     mod: {ExGrok.Application, []}]
  end

  defp deps do
    [{:ex_doc, "~> 0.14", only: :dev},
     {:dialyxir, "~> 0.3.5", only: :dev},
     {:credo, "~> 0.5", only: [:dev, :test]}]
  end

  defp description do
    """
    Low dependencies ngrok wrapper.
    """
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md"],
     maintainers: ["Paweł Dawczak"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/pdawczak/ex_grok"}]
  end

  defp aliases do
    ["check": ["dialyzer", "credo --strict"]]
  end
end
