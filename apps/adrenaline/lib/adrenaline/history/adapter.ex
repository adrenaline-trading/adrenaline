defmodule Adrenaline.History.Adapter do
  @moduledoc """
  Defines callbacks to be implemented by specific historical
  price data adapters.
  """
  alias Adrenaline.History.{ Header, Bar}

  @doc """
  Reads the history basic information if any and returns a `Header` instance
  if successful. Otherwise returns an `:error` tuple. `:eof` is considered an
  error by this function and is also to be returned in the error tuple.

  Expected to position at the beginning of the first bar.
  """
  @callback read_header( IO.device()) :: { :ok, Header.t()} | { :error, any()}

  @doc """
  Reads a history bar if any and returns a `Bar` instance if successful.
  Otherwise returns an `:error` tuple or an `:eof`.

  Expected to position at the beginning of the subsequent bar.
  """
  @callback read_bar( IO.device()) :: { :ok, Bar.t()} | IO.nodata()
end
