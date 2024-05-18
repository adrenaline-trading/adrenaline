defmodule Adrenaline.History do
  @moduledoc """
  Exposes functions for reading price history data.

  Extendable with adapters via `Adrenaline.History.Adapter` behaviour.
  """
  alias Adrenaline.History.{ Header, Bar}
  alias AdrenalineShared.ETS
  require Logger

  @enforce_keys [ :header, :data]
  defstruct @enforce_keys

  @type data() :: ETS.table()
  @type adapter() :: module()
  @type store_bar() :: ( Bar.t(), data() -> { :ok, data()} | { :error, any()})
  @type init_storage() :: ( -> { :ok, data(), store_bar()} | { :error, any()})

  @type t() ::
          %__MODULE__{
            header: Header.t(),
            data: data()
          }

  @read_ahead 1_000_000

  @spec from_file( String.t(), adapter(), init_storage()) :: { :ok, t()} | { :error, any()}
  def from_file( filename, adapter, init_storage) do
    filename
    |> Path.expand()
    |> File.open( [ :read, { :read_ahead, @read_ahead}], &load_file( &1, adapter, init_storage))
    |> interpret_open_file()
  end

  defp interpret_open_file( { :ok, result}), do: result
  defp interpret_open_file( { :error, _} = error), do: error

  @spec load_file( File.io_device(), adapter(), init_storage()) :: { :ok, t()} | { :error, any()}
  defp load_file( file, adapter, init_storage) do
    with { :ok, header} <- adapter.read_header( file),
         { :ok, data, store_bar} <- init_storage.(),
         { :ok, data} <- store_next_bar( file, adapter, data, store_bar)
      do
      { :ok, new( header: header, data: data)}
    end
  end

  @spec new( map() | keyword()) :: t()
  defp new( args) do
    struct!( __MODULE__, args)
  end

  # Tail-recursively reads bars one after another via the provided adapter
  # then stores them via the provided `store_bar()` function.
  @spec store_next_bar( File.io_device(), adapter(), data(), store_bar()) :: { :ok, data()} | { :error, any()}
  defp store_next_bar( file, adapter, data, store_bar) do
    with { :ok, bar} <- adapter.read_bar( file),
         { :ok, data} <- store_bar.( bar, data)
      do
      store_next_bar( file, adapter, data, store_bar)
    else
      :eof ->
        { :ok, data}

      { :error, reason} = error ->
        Logger.error inspect( reason)
        error
    end
  end
end
