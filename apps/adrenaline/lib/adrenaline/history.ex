defmodule Adrenaline.History do
  @moduledoc """
  Exposes functions for reading price history data.

  Extendable with adapters via `Adrenaline.History.Adapter` behaviour.
  """

  # Chart activity storage behaviour.
  alias Adrenaline.History.Bar

  @type data() :: term()

  @doc """
  Initializes the history storage.
  """
  @callback init_storage() :: { :ok, data()} | { :error, any()}

  @doc """
  Stores a bar instance into storage.
  Returns the stored data identifier or the stored date itself.
  """
  @callback store_bar( data(), Bar.t()) :: { :ok, data()} | { :error, any()}

  alias Adrenaline.History.Header
  require Logger

  @enforce_keys [ :header, :data]
  defstruct @enforce_keys

  @type adapter() :: module()

  @typedoc """
  An Adrenaline.History storage implementation
  """
  @type storage() :: module()

  @type t() ::
          %__MODULE__{
            header: Header.t(),
            data: data()
          }

  @read_ahead 1_000_000

  @spec from_file( String.t(), adapter(), storage()) :: { :ok, t()} | { :error, any()}
  def from_file( filename, adapter, storage) do
    filename
    |> Path.expand()
    |> File.open( [ :read, { :read_ahead, @read_ahead}], &load_file( &1, adapter, storage))
    |> interpret_open_file()
  end

  defp interpret_open_file( { :ok, result}), do: result
  defp interpret_open_file( { :error, _} = error), do: error

  @spec load_file( File.io_device(), adapter(), storage()) :: { :ok, t()} | { :error, any()}
  defp load_file( file, adapter, storage) do
    with { :ok, header} <- adapter.read_header( file),
         { :ok, data} <- storage.init_storage(),
         { :ok, data} <- store_next_bar( file, adapter, data, storage)
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
