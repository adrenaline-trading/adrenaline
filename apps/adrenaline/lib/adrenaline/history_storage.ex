defmodule Adrenaline.HistoryStorage do
  @moduledoc """
  Exposes functions for reading price history data.

  Extendable with adapters via `Adrenaline.History.Adapter` behaviour.
  """

  # Chart activity storage behaviour.
  alias AdrenalineShared.History
  require Logger

  @type data() :: History.data()
  @type adapter() :: module()

  @doc """
  Initializes the history storage.
  """
  @callback init() :: { :ok, data()} | { :error, any()}

  @doc """
  Stores a bar instance into storage.
  Returns the stored data identifier or the stored date itself.
  """
  @callback store_bar( data(), History.Bar.t()) :: { :ok, data()} | { :error, any()}

  @typedoc """
  An Adrenaline.History storage implementation
  """
  @type storage() :: module()

  @read_ahead 1_000_000

  @spec from_file( String.t(), adapter(), storage()) :: { :ok, History.t()} | { :error, any()}
  def from_file( filename, adapter, storage) do
    filename
    |> Path.expand()
    |> File.open( [ :read, { :read_ahead, @read_ahead}], &load_file( &1, adapter, storage))
    |> interpret_open_file()
  end

  defp interpret_open_file( { :ok, result}), do: result
  defp interpret_open_file( { :error, _} = error), do: error

  @spec load_file( File.io_device(), adapter(), storage()) :: { :ok, History.t()} | { :error, any()}
  defp load_file( file, adapter, storage) do
    with { :ok, header} <- adapter.read_header( file),
         { :ok, data} <- storage.init(),
         { :ok, data} <- store_next_bar( file, adapter, data, storage)
      do
      { :ok, History.new( header: header, data: data)}
    end
  end

  # Tail-recursively reads bars one after another via the provided adapter
  # then stores them via the provided `store_bar()` function.
  @spec store_next_bar( File.io_device(), adapter(), data(), storage()) :: { :ok, data()} | { :error, any()}
  defp store_next_bar( file, adapter, data, storage) do
    with { :ok, bar} <- adapter.read_bar( file),
         { :ok, data} <- storage.store_bar( data, bar)
      do
      store_next_bar( file, adapter, data, storage)
    else
      :eof ->
        { :ok, data}

      { :error, reason} = error ->
        Logger.error inspect( reason)
        error
    end
  end
end
