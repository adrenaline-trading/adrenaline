defmodule Adrenaline.History do
  @moduledoc """
  Exposes functions for reading price history data.

  Extendable with adapters via `Adrenaline.History.Adapter` behaviour.
  """
  alias Adrenaline.History.{ ChartInfo, Bar}
  require Logger

  @read_ahead 1_000_000

  @type adapter() :: module()
  @type storage() :: any()
  @type store_bar() :: ( Bar.t(), storage() -> { :ok, storage()} | { :error, any()})
  @type init_storage() :: ( -> { :ok, storage(), store_bar()} | { :error, any()})

  @spec load_file( String.t(), adapter(), init_storage()) :: { :ok, ChartInfo.t(), storage()} | { :error, any()}
  def load_file( filename, adapter, init_storage) do
    filename
    |> Path.expand()
    |> File.open( [ :read, { :read_ahead, @read_ahead}], &do_load_file( &1, adapter, init_storage))
    |> interpret_open_file()
  end

  defp interpret_open_file( { :ok, result}), do: result
  defp interpret_open_file( { :error, _} = error), do: error

  @spec do_load_file( File.io_device(), adapter(), init_storage()) ::
          { :ok, ChartInfo.t(), storage()} | { :error, any()}
  defp do_load_file( file, adapter, init_storage) do
    with { :ok, chart_info} <- adapter.read_info( file),
         { :ok, storage, store_bar} <- init_storage.(),
         { :ok, storage} <- store_next_bar( file, adapter, storage, store_bar)
      do
      { :ok, chart_info, storage}
    end
  end

  # Tail-recursively reads bars one after another via the provided adapter
  # then stores them via the provided `store_bar()` function.
  @spec store_next_bar( File.io_device(), adapter(), storage(), store_bar()) :: { :ok, storage()} | { :error, any()}
  defp store_next_bar( file, adapter, storage, store_bar) do
    with { :ok, bar} <- adapter.read_bar( file),
         { :ok, storage} <- store_bar.( bar, storage)
      do
      store_next_bar( file, adapter, storage, store_bar)
    else
      :eof ->
        { :ok, storage}

      { :error, reason} = error ->
        Logger.error inspect( reason)
        error
    end
  end
end
