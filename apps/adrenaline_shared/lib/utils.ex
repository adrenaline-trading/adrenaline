defmodule AdrenalineShared.Utils do
  @type datetime() :: DateTime.t() | NaiveDateTime.t() | Date.t()
  @type timeframe() :: atom() | { atom(), non_neg_integer()}

  @spec shift_datetime( timeframe(), datetime(), integer()) :: datetime()
  def shift_datetime( timeframe, datetime, shift)

  def shift_datetime( { time_unit, unit_count}, datetime, shift) do
    Timex.shift( datetime, [ { time_unit, unit_count * shift}])
  end

  def shift_datetime( tf, dt, shift) when is_atom( tf) do
    tf
    |> timeframe_shift()
    |> shift_datetime( dt, shift)
  end

  # todo:
  # make :m1 & co. standard timeframe constants while using the following for chart timeframe,
  # so the function will no longer be needed
  defp timeframe_shift( :m1), do: { :minutes, 1}
  defp timeframe_shift( :m5), do: { :minutes, 5}
  defp timeframe_shift( :m15), do: { :minutes, 15}
  defp timeframe_shift( :m30), do: { :minutes, 30}
  defp timeframe_shift( :h1), do: { :hours, 1}
  defp timeframe_shift( :h4), do: { :hours, 4}
  defp timeframe_shift( :d1), do: { :days, 1}
  defp timeframe_shift( :w), do: { :weeks, 1}
  defp timeframe_shift( :mn), do: { :months, 1}

  @spec unix_time( Date.t() | DateTime.t() | NaiveDateTime.t()) :: integer()
  def unix_time( date_or_datetime_or_naive_date_time)

  def unix_time( %Date{} = date) do
    DateTime.new!( date, Time.new!( 0, 0, 0))
    |> unix_time()
  end

  def unix_time( %NaiveDateTime{} = naive_datetime) do
    DateTime.from_naive!(naive_datetime, "Etc/UTC")
    |> unix_time()
  end

  def unix_time( %DateTime{} = datetime) do
    DateTime.to_unix( datetime)
  end
end
