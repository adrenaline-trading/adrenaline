defmodule AdrenalineShared.ETS do
  @type table() :: :ets.tid()
  @type key() :: term()
  @type object() :: { key(), any()}

  @spec first_value( table()) :: any() | nil
  def first_value( table) do
    first( table)
    |> value()
  end

  @spec first( table()) :: object() | nil
  def first( table) do
    if key = first_key( table) do
      :ets.lookup( table, key)
      |> List.first()
    end
  end

  @spec first_key( table()) :: key() | nil
  def first_key( table) do
    :ets.first( table)
    |> maybe_end()
  end

  @spec last_value( table()) :: any() | nil
  def last_value( table) do
    last( table)
    |> value()
  end

  @spec last( table()) :: object() | nil
  def last( table) do
    if key = last_key( table) do
      :ets.lookup( table, key)
      |> List.last()
    end
  end

  @spec last_key( table()) :: key() | nil
  def last_key( table) do
    :ets.last( table)
    |> maybe_end()
  end

  defp value( { _key, value}), do: value
  defp value( nil), do: nil

  defp maybe_end( :"$end_of_table"), do: nil
  defp maybe_end( other), do: other

  @type match_pattern() :: atom() | tuple()
  @type match_spec() :: [ { match_pattern(), [ term()], [ term()]}]

  @spec select( table(), match_spec()) :: [ term()]
  def select( table, match_spec) do
    :ets.select( table, match_spec)
  end
end
