defmodule Illuminati.MixProject do
  use Mix.Project

  def project do
    [
      app: :illuminati,
      version: ("VERSION" |> File.read! |> String.trim),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # excoveralls
      test_coverage:      [tool: ExCoveralls],
      preferred_cli_env:  [
        "coveralls":            :test,
        "coveralls.travis":     :test,
        "coveralls.circle":     :test,
        "coveralls.semaphore":  :test,
        "coveralls.post":       :test,
        "coveralls.detail":     :test,
        "coveralls.html":       :test,
      ],
      # dialyxir
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore",
        plt_add_apps: [
          :mix
        ]
      ],
      # ex_doc
      name:         "Illuminati",
      source_url:   "https://github.com/coingaming/illuminati",
      homepage_url: "https://github.com/coingaming/illuminati",
      docs:         [main: "readme", extras: ["README.md"]],
      # hex.pm stuff
      description:  "Macro utilities for logging and monitoring",
      package: [
        organization: "coingaming",
        licenses: ["Apache 2.0"],
        files: ["lib", "priv", "mix.exs", "README*", "VERSION*"],
        maintainers: ["timCF"],
        links: %{
          "GitHub" => "https://github.com/coingaming/illuminati",
          "Author's home page" => "https://timcf.github.io/",
        }
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Illuminati.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_statsd, "~> 0.5.4", organization: "coingaming"},
      {:logstash_json, "~> 0.7.0", [env: :prod, repo: "hexpm", hex: "logstash_json"]},
      # development tools
      {:excoveralls, "~> 0.8",            only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5",               only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18",                only: [:dev, :test], runtime: false},
      {:credo, "~> 0.9",                  only: [:dev, :test], runtime: false},
      {:boilex, "~> 0.2",                 only: [:dev, :test], runtime: false},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
