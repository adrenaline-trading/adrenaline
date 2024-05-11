defmodule Adrenaline.History.Header do
  @moduledoc """
  History header information
  """
  @enforce_keys [ :format, :copyrighted?, :symbol, :time_unit, :period, :digits, :proprietary]
  defstruct @enforce_keys

  @type time_unit() :: :minute | :second | :millisecond | :microsecond

  @type t() ::
          %__MODULE__{
            format: String.t(),
            copyrighted?: boolean(),
            symbol: String.t(),
            time_unit: time_unit(),
            period: non_neg_integer(),
            digits: non_neg_integer(),
            proprietary: map()
          }

  @doc """
  Instantiates structure.
  """
  @spec new( keyword() | map()) :: t()
  def new( args) do
    struct!( __MODULE__, args)
  end
end
