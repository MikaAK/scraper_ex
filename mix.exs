defmodule ScraperEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :scraper_ex,
      version: "0.1.0",
      elixir: "~> 1.10",
      description: "Scraping with hound made a bit easier and quicker to use for writing applications",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],

      dialyzer: [
        plt_add_apps: [:ex_unit, :mix, :credo, :jason],
        list_unused_filters: true,
        plt_local_path: ".check",
        plt_core_path: ".check"
      ],

      preferred_cli_env: [
        dialyzer: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hound, "~> 1.1"},
      {:floki, "~> 0.34"},
      {:error_message, "~> 0.2"},
      {:telemetry, "~> 1.1"},
      {:telemetry_metrics, "~> 0.6.1"},

      {:ex_doc, ">= 0.0.0", optional: true, only: :dev},
      {:dialyxir, "~> 1.0", optional: true, only: :test, runtime: false},

      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.6", only: [:test, :dev], runtime: false},
      {:blitz_credo_checks, "~> 0.1", only: [:test, :dev], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Mika Kalathil"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mikaak/scraper_ex"},
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib config)
    ]
  end

  defp docs do
    [
      main: "ScraperEx",
      source_url: "https://github.com/mikaak/scraper_ex"
    ]
  end
end
