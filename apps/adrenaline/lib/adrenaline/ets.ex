defmodule Adrenaline.ETS do
  import Extructure
  alias Adrenaline.Utils

  @type table() :: :ets.tid()
  @type key() :: term()
  @type object() :: { key(), any()}

  # todo: retrieve tables from a pool where they're named (with strings) and reused once no longer needed
  def init_storage() do
    table = :ets.new( :table, [ :ordered_set, :private])

    { :ok, table, &insert_data/2}
  end

  defp insert_data( data, table) do
    key =
      elem( data, 0)
      |> Utils.unix_time()

    :ets.insert( table, { key, data})

    { :ok, table}
  end

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
  @type timeframe() :: atom() | { atom(), non_neg_integer()}

  require Matcha

  # Returns ETS match specification for retrieving
  # a time window of the ETS table data.
  # Fails if `first` or either of `last` or `count` are missing.
  @spec time_window_spec( timeframe(), keyword()) :: match_spec()
  def time_window_spec( timeframe, opts) do
    [ first, _last, _count] <~ opts

    last = last || Utils.shift_datetime( timeframe, first, count - 1)
    unix_first = Utils.unix_time( first)
    unix_last = Utils.unix_time( last)

    Matcha.spec do
      { unix_time, data} when unix_time >= unix_first and unix_time <= unix_last -> data
    end
    |> Matcha.Spec.source()
  end

  @spec select( table(), match_spec()) :: [ term()]
  def select( table, match_spec) do
    :ets.select( table, match_spec)
  end
end
