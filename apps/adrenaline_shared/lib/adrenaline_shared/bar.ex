defmodule AdrenalineShared.Bar do
  @moduledoc """
  Size/access optimized OHLC bar definition.
  """
  import Extructure

  @type datetime() :: Date.t() | DateTime.t() | NaiveDateTime.t()
  @type open() :: float()
  @type high() :: float()
  @type low() :: float()
  @type close() :: float()
  @type volume() :: non_neg_integer()

  @type t() :: { datetime(), open(), high(), low(), close(), volume()}

  @doc """
  Instantiates a new `Bar` tuple.
  """
  @spec new( map() | keyword()) :: t()
  def new( args) do
    [ datetime, open, high, low, close, volume] <~ args

    { datetime, open, high, low, close, volume}
  end

  @spec datetime( t()) :: datetime()
  def datetime( { datetime, _open, _high, _low, _close, _volume}), do: datetime

  @spec open( t()) :: open()
  def open( { _datetime, open, _high, _low, _close, _volume}), do: open

  @spec high( t()) :: high()
  def high( { _datetime, _open, high, _low, _close, _volume}), do: high

  @spec low( t()) :: low()
  def low( { _datetime, _open, _high, low, _close, _volume}), do: low

  @spec close( t()) :: close()
  def close( { _datetime, _open, _high, _low, close, _volume}), do: close

  @spec volume( t()) :: volume()
  def volume( { _datetime, _open, _high, _low, _close, volume}), do: volume

  defguard is_bar( term) when tuple_size( term) == 6
end
