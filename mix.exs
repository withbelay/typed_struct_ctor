defmodule TypedStructCtor.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_struct_ctor,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "TypedStructCtor",
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    []
  end

  defp description() do
    """
    A `TypedStruct` plugin utilizing Ecto.Changeset validation enabled by the plugin `TypedStructEctoChangeset` to
    provide validating constructors"
    """
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
      {:typedstruct, "~> 0.5.2", only: [:dev, :test], runtime: false},
      {:typed_struct_ecto_changeset, "~> 1.0.0"}
    ]
  end
end
