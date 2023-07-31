defmodule TypedStructCtor do
  @moduledoc """
  """
  use TypedStruct.Plugin
  use Ecto.Schema
  import Ecto.Changeset

  defmacro init(opts) do
    quote do
      Module.register_attribute(__MODULE__, :required?, accumulate: false)
      Module.register_attribute(__MODULE__, :all_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :default_apply_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :required_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :non_mapped_fields, accumulate: true)

      globally_required = Keyword.get(unquote(opts), :required, true)
      Module.put_attribute(__MODULE__, :required?, globally_required)
    end
  end

  def field(name, type, opts, env) do
    quote bind_quoted: [name: name, type: Macro.escape(type), opts: Macro.escape(opts), env: Macro.escape(env)] do
      TypedStructCtor.__field__(name, type, opts, env)
    end
  end

  def __field__(name, _type, opts, %Macro.Env{module: mod}) do
    Module.put_attribute(mod, :all_fields, {name, true})

    if default_apply = Keyword.get(opts, :default_apply) do
      Module.put_attribute(mod, :default_apply_fields, {name, default_apply})
    end

    if !Keyword.get(opts, :mappable?, true) do
      Module.put_attribute(mod, :non_mapped_fields, {name, true})
    end

    globally_required = Module.get_attribute(mod, :required?)

    if Keyword.get(opts, :required, globally_required) do
      Module.put_attribute(mod, :required_fields, {name, opts})
    end
  end

  def after_definition(_opts) do
    quote unquote: false do
      def __defaults__, do: @default_apply_fields |> Enum.reverse()
      def __required__, do: @required_fields |> Keyword.keys() |> Enum.reverse()
      def __not_mapped__, do: @non_mapped_fields |> Keyword.keys() |> Enum.reverse()
      def __all__, do: @all_fields |> Keyword.keys() |> Enum.reverse()

      Module.delete_attribute(__MODULE__, :required?)
      Module.delete_attribute(__MODULE__, :all_fields)
      Module.delete_attribute(__MODULE__, :default_apply_fields)
      Module.delete_attribute(__MODULE__, :required_fields)
      Module.delete_attribute(__MODULE__, :non_mapped_fields)

      @spec new() :: {:ok, t()} | {:error, Ecto.Changeset.t()}
      def new(), do: new(%{})

      @spec new!() :: t()
      def new!(), do: new!(%{})

      @spec new(map()) :: {:ok, t()} | {:error, :attributes_must_be_a_map} | {:error, Ecto.Changeset.t()}
      def new(attrs) do
        TypedStructCtor.new(attrs, {__ENV__.module, __all__(), __required__(), __defaults__()})
      end

      def new!(attrs) do
        case new(attrs) do
          {:ok, val} -> val
          {:error, :attributes_must_be_a_map} -> raise "Invalid #{__ENV__.module}.new!(): Attributes must be a map}"
          {:error, cs} -> raise "Invalid #{__ENV__.module}.new!(): #{inspect(cs.errors)}"
        end
      end

      @spec from(struct()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
      def from(base_struct), do: from(base_struct, %{})

      @spec from!(struct()) :: t()
      def from!(base_struct), do: from!(base_struct, %{})

      @spec from(struct(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
      def from(struct, attrs) do
        TypedStructCtor.from(
          struct,
          attrs,
          __not_mapped__(),
          {__ENV__.module, __all__(), __required__(), __defaults__()}
        )
      end

      @spec from(struct(), map()) :: t()
      def from!(base_struct, attrs) when is_struct(base_struct) do
        case from(base_struct, attrs) do
          {:ok, val} -> val
          {:error, :attributes_must_be_a_map} -> raise "Invalid #{__ENV__.module}.from!(): Attributes must be a map}"
          {:error, cs} -> raise "Invalid #{__MODULE__}.from!(): #{inspect(cs.errors)}"
        end
      end
    end
  end

  def new(attrs, {_mod, _all, _required, _defaults}) when not is_map(attrs), do: {:error, :attributes_must_be_a_map}

  def new(attrs, {mod, all, required, defaults}) do
    mod.__struct__()
    |> cast(attrs, all)
    |> apply_defaults(defaults)
    |> validate_required(required)
    |> apply_action(:new)
  end

  def from(base_struct, attrs, not_mapped, {_mod, _all, _required, _defaults} = state) when is_struct(base_struct) do
    base_struct
    |> Map.from_struct()
    |> Map.drop(not_mapped)
    |> Map.merge(attrs)
    |> new(state)
  end

  def apply_defaults(%Ecto.Changeset{} = changeset, defaults) do
    applied_default = fn
      changeset, field, {m, f, a} -> get_change(changeset, field, apply(m, f, a))
      changeset, field, {f, a} -> get_change(changeset, field, apply(f, a))
    end

    Enum.reduce(defaults, changeset, fn {field, apply}, changeset ->
      value = applied_default.(changeset, field, apply)
      cast(changeset, %{field => value}, [field])
    end)
  end
end
