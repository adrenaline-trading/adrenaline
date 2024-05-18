defmodule AdrenalineShared.Storage do
  @moduledoc """
  Chart activity storage behaviour.
  """

  @typedoc """
  A specific storage identifier or the storage itself as returned
  when initialized and as supplied when used to store activities.
  """
  @type t() :: term()

  @typedoc """
  A value activity taking place at in a certain moment of time or
  time index, e.g. an OHLC bar.
  """
  @type activity() :: term()

  @doc """
  Initializes the activity storage.
  """
  @callback init() :: { :ok, t()} | { :error, any()}

  @doc """
  Stores an activity instance into a storage.
  Returns the storage identifier or the storage structure itself.
  """
  @callback store( t(), activity()) :: { :ok, t()} | { :error, any()}
end
