defmodule AdrenalineShared.ETS do
  @type table() :: :ets.tid()
  @type key() :: term()
  @type object() :: { key(), term()}

  @spec first_term( table()) :: term() | nil
  def first_term( table) do
    find_term( table, :ets.first( table))
  end

  @spec last_term( table()) :: term() | nil
  def last_term( table) do
    find_term( table, :ets.last( table))
  end

  @spec next_term( table(), key()) :: term() | nil
  def next_term( table, key) do
    find_term( table, :ets.next( table, key))
  end

  @spec find_term( table(), key()) :: term() | nil
  def find_term( table, key) do
    case :ets.lookup( table, key) do
      [ { _key, term}] ->
        term

      [] ->
        nil
    end
  end

  @type match_pattern() :: atom() | tuple()
  @type match_spec() :: [ { match_pattern(), [ term()], [ term()]}]

  @spec select( table(), match_spec()) :: [ term()]
  def select( table, match_spec) do
    :ets.select( table, match_spec)
  end
end
