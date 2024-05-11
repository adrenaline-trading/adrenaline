defmodule Adrenaline.Adapters.MT4 do
  @moduledoc """
  MT4 history file adapter.
  """
  alias Adrenaline.Adapters.MT4.{ MT4Header, MT4Bar}
  alias Adrenaline.History.{ Header, Bar}

  @behaviour Adrenaline.History.Adapter

  @impl true
  def read_header( device) do
    case read_mt4_header( device) do
      { :ok, header} ->
        { :ok,
          Header.new(
            format: "MT4",
            copyrighted?: true,
            symbol: header.symbol,
            time_unit: :minute,
            period: header.period,
            digits: header.digits,
            proprietary: Map.from_struct( header)
          )}

      { :error, _} = error ->
        error

      :eof ->
        { :error, :eof}
    end
  end

  @impl true
  def read_bar( device) do
    with { :ok, bar} <- read_mt4_bar( device) do
      { :ok,
        bar
        |> Map.from_struct()
        |> Bar.new()}
    end
  end

  @spec read_mt4_header( IO.device()) :: { :ok, MT4Header.t()} | IO.nodata()
  defp read_mt4_header( device) do
    device
    |> IO.binread( MT4Header.size())
    |> maybe_from_binary( &MT4Header.from_binary/1)
  end

  @doc false
  @spec read_mt4_bar( IO.device()) :: { :ok, MT4Bar.t()} | IO.nodata()
  defp read_mt4_bar( device) do
    device
    |> IO.binread( MT4Bar.size())
    |> maybe_from_binary( &MT4Bar.from_binary/1)
  end

  @spec maybe_from_binary( iodata() | IO.nodata(), ( binary() -> struct())) :: { :ok, struct()} | IO.nodata()
  defp maybe_from_binary( hst_or_nodata, fun) do
    case hst_or_nodata do
      hst when is_binary( hst) ->
        { :ok, fun.( hst)}

      :eof ->
        :eof

      { :error, _} = error ->
        error
    end
  end
end
