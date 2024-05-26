defmodule Adrenaline.Adapters.MT4.MT4Header do
  @moduledoc """
  ```cpp
  #pragma pack(push, 1)

  struct HstHeader {
    INT			version;
    CHAR		copyright [64];
    CHAR		symbol [12];
    INT			period;
    INT			digits;
    __time32_t	timesign;
    __time32_t	last_sync;
    INT			unused [13];
  };

  #pragma pack(pop)
  ```
  """
  @enforce_keys [ :version, :copyright, :symbol, :period, :digits, :timesign, :last_sync]
  defstruct @enforce_keys

  @type t() ::
          %{
            version: integer(),
            copyright: String.t(),
            symbol: binary(),
            period: integer(),
            digits: integer(),
            timesign: DateTime.t(),
            last_sync: DateTime.t() | nil
          }

  @size byte_size( <<
    0 :: 32,
    String.duplicate( " ", 64) :: binary-size( 64),
    String.duplicate( " ", 12) :: binary-size( 12),
    0 :: little-unsigned-integer-32,
    0 :: little-unsigned-integer-32,
    0 :: little-unsigned-integer-32,
    0 :: little-unsigned-integer-32,
    0 :: 32 * 13
  >>)

  @spec size() :: non_neg_integer()
  def size(), do: @size

  def from_binary( hst) do
    <<
      version :: little-unsigned-integer-32,
      copyright :: binary-size( 64),
      symbol :: binary-size( 12),
      period :: little-unsigned-integer-32,
      digits :: little-unsigned-integer-32,
      timesign :: little-unsigned-integer-32,
      last_sync :: little-unsigned-integer-32,
      _unused :: 32 * 13
    >> = hst

    new(
      version: version,
      copyright: ascii_to_string( copyright),
      symbol: ascii_to_string( symbol),
      period: period,
      digits: digits,
      timesign: DateTime.from_unix!( timesign),
      last_sync: last_sync != 0 && DateTime.from_unix!( last_sync) || nil
    )
  end

  defp ascii_to_string( ascii) do
    Enum.join( for << c :: utf8 <- ascii>>, c != 0, do: << c :: utf8>>)
  end

  defp new( args) do
    struct!( __MODULE__, args)
  end
end
