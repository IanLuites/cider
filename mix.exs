defmodule Cider.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cider,
      version: "0.3.0",
      elixir: "~> 1.8",
      description: "CIDR library for Elixer.",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Docs
      name: "Cider",
      source_url: "https://github.com/IanLuites/cider",
      homepage_url: "https://github.com/IanLuites/cider",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def package do
    [
      name: :cider,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        # Elixir
        "lib/cider.ex",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/cider"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Testing, documentation, and releases
      {:analyze, "~> 0.1.3", optional: true, runtime: false, only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.4", optional: true, runtime: false, only: [:dev]}
    ]
  end
end
