# TypedStructCtor

A TypedStruct plugin to add validating constructors to a TypedStruct module

The [TypedStruct](https://hexdocs.pm/typed_struct/TypedStruct.html) macro wraps field definitions to reduce boilerplate
needed to define elixir structs and provides a
[plugin system](https://hexdocs.pm/typed_struct/TypedStruct.Plugin.html) for clients to extend the DSL.

`TypedStructCtor` uses the `__changeset__` "reflection" function added by the plugin
[TypedStructEctoChangeset](https://hexdocs.pm/typed_struct_ecto_changeset/TypedStructEctoChangeset.html) enabling
Ecto.Changeset.cast

This plugin adds 5 constructors, `new/0`, `new/1`, `new!/1`, `from/2`, and `from!/2` to the given module.  
Ecto `cast` is called for all attributes provided to the constructors, defaults are applied where needed, and
validation is performed.  

The `new` functions return an ok/error tuple, while the `new!` functions return the struct, or
raise if there were issues with `cast` or validation.

The `from` functions are intended for messaging environments where a new message is created from a disjoint set of
values from a source message.  They are similar to the `new` functions but accept a "base struct" as the first argument 
and a map of attributes as the second argument.  The base struct is mapped first to the field values, and the attributes 
are merged on top.

## Rationale

[Ecto.Changeset](https://hexdocs.pm/ecto/Ecto.Changeset.html) is a great way to create validated
structs.  However, if you're creating many validated struct they quickly become "noise", where writing
these functions can be tedious, and bugs are easily introduced as struct changes are easily overlooked.
When you include the effort needed to write boilerplate tests for boilerplate code, it can be tempting to skip struct
validation altogether.

To reduce the boilerplate, and make it easier to write tests, this plugin adds a set of constructors to your struct
built from the field definitions themselves.  Thus the constructors are always up to date with the field definitions,
and 

The `new` function takes an optional map of attributes, does 
[Changeset.cast](https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) of all values matching the defined
fields, validates any required fields, and finally does 
[Changeset.apply_action](https://hexdocs.pm/ecto/Ecto.Changeset.html#apply_action/2) to validate the changeset.
Returns `{:ok, <struct>}` if everything is OK, `{:error, <changeset>}` if there were issues with `cast` or validation.
Because it's necessary to properly handle mappable fields, if a struct is passed to the `new` function,
`{:error, :attributes_must_be_a_map}` is returned; use one of the `from` functions for that use case as described below.

The `new!` function calls `new` and returns the struct if successful, and raises if not


## Required Fields
By default, all fields are required when calling the constructors.  Meaning you'll get a changeset error if the 
field does not have a default, and you don't provide an attribute value for it in the constructor.

You can override this by passing `required: false` to the plugin

  ```elixir
  typedstruct do
    plugin(TypedStructEctoChangeset)
    plugin(TypedStructCtor, required: false)

    field :this_field_is_not_required, :string
  end
  ```

Or by passing `required: false` to the `field` definition.

  ```elixir
  typedstruct do
    plugin(TypedStructEctoChangeset)
    plugin(TypedStructCtor)

    field :this_field_is_not_required, :string, required: false
  end
  ```

## Field-level Defaults
`default` and `default_apply` can be provided to the `field` definition to specify a default value for the field.

Though you can specify both `default` and `default_apply`, only one will be used.
`default` will be used with Elixir's struct syntax (e.g. `%AStruct{}`).
`default_apply` will be invoked when `new()` or `new!()` is used to construct (e.g. `AStruct.new!()`)

  ```elixir
    defmodule AStructWithDefaulting do
      use TypedStruct

      typedstruct do
        plugin(TypedStructEctoChangeset)
        plugin(TypedStructCtor)

        field :field, :integer, default: 42, default_apply: {SomeModule, :some_function, ["55"]}
      end
    end

    iex()> %AStructWithDefaulting{}
    %AStructWithDefaulting{field: 42}

    iex()> AStructWithDefaulting.new!()
    %AStructWithDefaulting{field: 55}
  ```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `typed_struct_plugin_ctor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:typed_struct_ctor, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/typed_struct_ctor>.
