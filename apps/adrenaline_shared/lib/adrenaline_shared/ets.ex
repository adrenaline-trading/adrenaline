defmodule AdrenalineShared.ETS do
  @type table() :: :ets.tid()
  @type key() :: term()
  @type object() :: { key(), term()}

  @spec first_term( table()) :: term() | nil
  def first_term( table) do
    first( table)
    |> term()
  end

  def first( table) do
    find_one( table, :ets.first( table))
  end

  @spec last_term( table()) :: term() | nil
  def last_term( table) do
    last( table)
    |> term()
  end

  @spec last( table()) :: object() | nil
  def last( table) do
    find_one( table, :ets.last( table))
  end

  @spec next_term( table(), key()) :: term() | nil
  def next_term( table, key) do
    next( table, key)
    |> term()
  end

  @spec next( table(), key()) :: object() | nil
  def next( table, key) do
    find_one( table, :ets.next( table, key))
  end

  @spec find_term( table(), key()) :: term() | nil
  def find_term( table, key) do
    if object = find_one( table, key) do
      elem( object, 1)
    end
  end

  @spec find_one( table(), key()) :: object()
  def find_one( table, key) do
    case :ets.lookup( table, key) do
      [ object] ->
        object

      [] ->
        nil
    end
  end

  @spec term( object() | nil) :: term() | nil
  defp term( { _key, term}), do: term
  defp term( nil), do: nil

  @type match_pattern() :: atom() | tuple()
  @type match_spec() :: [ { match_pattern(), [ term()], [ term()]}]

  @spec select( table(), match_spec()) :: [ term()]
  def select( table, match_spec) do
    :ets.select( table, match_spec)
  end
end
