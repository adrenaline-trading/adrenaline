defmodule Adrenaline.Adapters.MT4.MT4Bar do
  @moduledoc """
  Bar data as stored in the MT4 history file.

  ```cpp
  #pragma pack(push, 1)

  struct HstRateNew {
    __time64_t  ctm;
    double  open;
    double  low;
    double  high;
    double  close;
    unsigned __int64	vol_tick;
    __int32  spread;
    unsigned __int64	vol_real;
  };

  #pragma pack(pop)
  ```
  """
  @enforce_keys [ :time, :open, :high, :low, :close, :volume]
  defstruct @enforce_keys

  @type t() ::
          %__MODULE__{
            time: DateTime.t(),
            open: float(),
            high: float(),
            low: float(),
            close: float(),
            volume: non_neg_integer() | nil
          }

  @size byte_size( <<
    0 :: unsigned-little-integer-64,
    0 :: little-float-64,
    0 :: little-float-64,
    0 :: little-float-64,
    0 :: little-float-64,
    0 :: little-unsigned-integer-64,
    0 :: little-integer-32,
    0 :: little-unsigned-integer-64
  >>)

  @spec size() :: non_neg_integer()
  def size(), do: @size

  # todo: ensure volume is actually vol_real and not vol_tick
  @spec from_binary( binary()) :: t()
  def from_binary( hst) do
    <<
      time :: unsigned-little-integer-64,
      open :: little-float-64,
      high :: little-float-64,
      low :: little-float-64,
      close :: little-float-64,
      _vol_tick :: little-unsigned-integer-64,
      _spread :: little-integer-32,
      vol_real :: little-unsigned-integer-64
    >> = hst

    time =
      time
      |> DateTime.from_unix!()
      |> DateTime.to_naive()

    new(
      time: time,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: vol_real
    )
  end

  @spec new( keyword() | map()) :: t()
  defp new( args) do
    struct!( __MODULE__, args)
  end
end
