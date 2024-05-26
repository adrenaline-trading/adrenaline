defmodule Adrenaline.ETSHistoryStorage do
  @moduledoc """
  ETS based implementation of the OHLC bar history storage.
  """
  import Extructure
  alias AdrenalineShared.{ Utils, ETS}

  @behaviour Adrenaline.HistoryStorage

  # todo: retrieve tables from a pool where they're named (with strings) and reused once no longer needed
  @impl true
  def init() do
    table = :ets.new( :table, [ :ordered_set, :private])

    { :ok, table}
  end

  @impl true
  def store_bar( table, bar_tuple) when is_tuple( bar_tuple) do
    key =
      elem( bar_tuple, 0)
      |> Utils.unix_time()

    :ets.insert( table, { key, bar_tuple})

    { :ok, table}
  end

  @type timeframe() :: atom() | { atom(), non_neg_integer()}

  require Matcha

  @doc """
  Returns ETS match specification for retrieving
  a time window of the ETS table data.
  Fails if `first` or either of `last` or `count` are missing.
  """
  @spec time_window_spec( timeframe(), keyword()) :: ETS.match_spec()
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
end
