defmodule Bitcoin.MixProject do
  use Mix.Project

  def project do
    [
      app: :bitcoin,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [],
      extra_applications: [:logger],
      mod: {Bitcoin.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:uuid, "~> 1.1"},
      {:chord, in_umbrella: true},
      {:seed, in_umbrella: true},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 1.4"}
    ]
  end
end
