defmodule Adrenaline.History.Bar do
  @moduledoc """
  Size/access optimized OHLC bar definition.
  """
  import Extructure

  @type time() :: NaiveDateTime.t()
  @type open() :: float()
  @type high() :: float()
  @type low() :: float()
  @type close() :: float()
  @type volume() :: non_neg_integer()

  @type t() :: { time(), open(), high(), low(), close(), volume()}

  @doc """
  Instantiates a new `Bar` tuple.
  """
  @spec new( map() | keyword()) :: t()
  def new( args) do
    [ time, open, high, low, close, volume] <~ args

    { time, open, high, low, close, volume}
  end

  @spec time( t()) :: time()
  def time( { time, _open, _high, _low, _close, _volume}), do: time

  @spec open( t()) :: open()
  def open( { _time, open, _high, _low, _close, _volume}), do: open

  @spec high( t()) :: high()
  def high( { _time, _open, high, _low, _close, _volume}), do: high

  @spec low( t()) :: low()
  def low( { _time, _open, _high, low, _close, _volume}), do: low

  @spec close( t()) :: close()
  def close( { _time, _open, _high, _low, close, _volume}), do: close

  @spec volume( t()) :: volume()
  def volume( { _time, _open, _high, _low, _close, volume}), do: volume
end
