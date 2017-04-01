defmodule Cider.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cider,
      version: "0.1.0",
      elixir: "~> 1.4",
      description: "CIDR library for Elixer.",
      package: package(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],

      # Docs
      name: "Cider",
      source_url: "https://github.com/IanLuites/cider",
      homepage_url: "https://github.com/IanLuites/cider",
      docs: [
        main: "readme",
        extras: ["README.md"],
      ],
    ]
  end

  def package do
    [
      name: :cider,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        "lib/cider.ex", "mix.exs", "README*", "LICENSE*", # Elixir
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/cider",
      },
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
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.15", only: :dev},
      {:excoveralls, "~> 0.6", only: :test},
      {:inch_ex, "~> 0.5", only: [:dev, :test]},
    ]
  end
end
