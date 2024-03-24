defmodule AdrenalineWeb.Assigns do
  @moduledoc """
  Defines macro to declare individual assign functions e.g:

  ```elixir
  defassign foo

  =>

  def assign_foo( socket, foo) do
    assign( socket, :foo, foo
  end
  ```

  also

  ```elixir
  defassign ready?

  =>

  def assign_ready( socket, ready?) do
    assign( socket, :ready?, ready?
  end
  ```
  """
  alias AdrenalineWeb.Assigns

  defmacro defassign( property) when is_atom( property) do
    name = Assigns.property_to_name( property)
    property_var = Macro.var( property, nil)

    quote do
      def unquote( :"assign_#{ name}")( socket, unquote( property_var)) do
        assign( socket, unquote( :"#{ property}"), unquote( property_var))
      end
    end
  end

  defmacro defassignp( property) when is_atom( property) do
    name = Assigns.property_to_name( property)
    property_var = Macro.var( property, nil)

    quote do
      defp unquote( :"assign_#{ name}")( socket, unquote( property_var)) do
        assign( socket, unquote( :"#{ property}"), unquote( property_var))
      end
    end
  end

  defmacro defassign( properties) when is_list( properties) do
    for property <- properties do
      quote do
        defassign unquote( property)
      end
    end
  end

  defmacro defassignp( properties) when is_list( properties) do
    for property <- properties do
      quote do
        defassignp unquote( property)
      end
    end
  end

  @doc false
  @spec property_to_name( atom()) :: atom()
  def property_to_name( property) when is_atom( property) do
    property
    |> Atom.to_string()
    |> String.trim_trailing( "?")
    |> String.to_atom()
  end
end
