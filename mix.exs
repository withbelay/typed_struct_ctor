defmodule TypedStructCtor.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_struct_ctor,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "Plugin for typed struct to integrate with changeset"
  end

  defp package() do
    [
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/withbelay/typed_struct_ctor"}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.10"},
      {:typed_struct, "~> 0.3.0"},
      {:typed_struct_ecto_changeset,
       github: "/withbelay/typed_struct_ecto_changeset", ref: "0771ea2b0fbcd1e49e75b9b6a55512d16aee1192"}
    ]
  end
end