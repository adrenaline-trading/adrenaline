defmodule AdrenalineWeb.Chart.ChartLive do
  use AdrenalineWeb, :live_view
  import Extructure
  alias Contex.{ Dataset, Plot, TimeScale, OHLC, OHLC.Overlayable}
  alias Phoenix.LiveView.Socket
  alias Adrenaline.History
  alias Adrenaline.Utils
  alias Adrenaline.ETS

  @typep timeframe() :: atom()

  @impl true
  def mount( _params, _session, socket) do
    { :ok, history} =
      History.from_file(
        "/data/vbox_shared/SPX500USD1440.hst",
        Adrenaline.Adapters.MT4,
        &ETS.init_storage/0
      )

    socket =
      socket
      |> assign_chart( nil)
      |> assign_style( :candle)
      |> assign_bull_color( "00FF77")
      |> assign_bear_color( "FF3333")
      |> assign_shadow_color( "000000")
      |> assign_colorized_bars( false)
      |> assign_zoom( 3)
      |> assign_timeframe( :d1)
      |> assign_connected( connected?( socket))
      |> store_dataset( history.data)

    { :ok, socket}
  end

  @impl true
  def handle_event( event, params, socket) do
    socket =
      case event do
        "redraw" ->
          redraw( params, socket)

        "keyup" ->
          handle_keyup( params, socket)

        "pane-" <> pane_event ->
          handle_pane_event( pane_event, socket)
      end

    { :noreply, socket}
  end

  # Redraws the SVG chart based on the new width and height
  @spec redraw( map(), Socket.t()) :: Socket.t()
  defp redraw( params, socket) do
    @[ width, height] <~ params

    socket
    |> assign_width( String.to_integer( width))
    |> assign_height( String.to_integer( height))
    |> recompute_chart()
  end

  # Handles a key up event
  @spec handle_keyup( map(), Socket.t()) :: Socket.t()
  defp handle_keyup( params, socket) do
    @[ key] <~ params

    case key do
      "+" ->
        zoom_in( socket)

      "-" ->
        zoom_out( socket)

      _ ->
        socket
    end
  end

  # Increases the zoom level if less than 6
  @spec zoom_in( Socket.t()) :: Socket.t()
  defp zoom_in( socket) do
    zoom( socket, & &1 < 6, & &1 + 1)
  end

  # Decreases the zoom level if greater than 0
  @spec zoom_out( Socket.t()) :: Socket.t()
  defp zoom_out( socket) do
    zoom( socket, & &1 > 0, & &1 - 1)
  end

  @spec zoom( Socket.t(), ( zoom -> boolean()), ( zoom -> zoom)) :: Socket.t()
        when zoom: non_neg_integer()
  defp zoom( socket, verifier, updater) do
    [ zoom] <~ socket.assigns

    if verifier.( zoom) do
      socket
      |> assign_zoom( updater.( zoom))
      |> recompute_chart()
    else
      socket
    end
  end

  # Handles a pane movement event on keydown
  @spec handle_pane_event( String.t(), Socket.t()) :: Socket.t()
  defp handle_pane_event( pane_event, socket)

  defp handle_pane_event( "prev-period", socket) do
    [ min_date] <~ socket.assigns

    shift_domain( socket, -4, &limit_min( &1, min_date))
  end

  defp handle_pane_event( "next-period", socket) do
    [ max_date] <~ socket.assigns

    shift_domain( socket, 4, &limit_max( &1, max_date))
  end

  defp handle_pane_event( "prev-page", socket) do
    [ interval_count, min_date] <~ socket.assigns

    shift_domain( socket, -interval_count, &limit_min( &1, min_date))
  end

  defp handle_pane_event( "next-page", socket) do
    [ interval_count, max_date] <~ socket.assigns

    shift_domain( socket, interval_count, fn date ->
      if Contex.Utils.date_compare( date, max_date) == :lt do
        date
      end
    end)
  end

  defp handle_pane_event( "first-page", socket) do
    [ min_date] <~ socket.assigns

    shift_domain( socket, 0, fn _ -> min_date end)
  end

  defp handle_pane_event( "last-page", socket) do
    [ timeframe, max_date, interval_count] <~ socket.assigns

    shift_domain( socket, 0, fn date ->
      new_domain_min = Utils.shift_datetime( timeframe, max_date, -interval_count)

      if Contex.Utils.date_compare( date, new_domain_min) == :gt do
        date
      else
        new_domain_min
      end
    end)
  end

  @spec limit_min( TimeScale.datetimes(), TimeScale.datetimes()) :: TimeScale.datetimes()
  defp limit_min( first, second) do
    Contex.Utils.safe_max( first, second)
  end

  @spec limit_max( TimeScale.datetimes(), TimeScale.datetimes()) :: TimeScale.datetimes()
  defp limit_max( first, second) do
    Contex.Utils.safe_min( first, second)
  end

  @spec shift_domain( Socket.t(), integer(), ( TimeScale.datetimes() -> TimeScale.datetimes() | nil)) :: Socket.t()
  defp shift_domain( socket, shift, limiter) do
    [ domain_min, timeframe] <~ socket.assigns

    new_domain_min = limiter.( Utils.shift_datetime( timeframe, domain_min, shift)) || domain_min

    if new_domain_min != domain_min do
      socket
      |> assign_domain_min( new_domain_min)
      |> recompute_chart()
    else
      socket
    end
  end

  @spec recompute_chart( Socket.t()) :: Socket.t()
  defp recompute_chart( socket) do
    [ _domain_min] <~ socket.assigns

    ohlc_svg = generate_ohlc_svg( socket.assigns)
    chart_domain = Process.get( :chart_domain)

    domain_min = domain_min || chart_domain.domain_min
    interval_count = chart_domain.interval_count

    socket
    |> assign_chart( ohlc_svg)
    |> assign_domain_min( domain_min)
    |> assign_interval_count( interval_count)
  end

  @spec generate_ohlc_svg( map()) :: Phoenix.HTML.safe()
  defp generate_ohlc_svg( args) do
    [ dataset, min_date,
      width, height,
      zoom, timeframe, _domain_min,
      style, bull_color, bear_color, shadow_color, colorized_bars] <~ args

    style = style == :bar && :tick || :candle

    opts = [
      mapping: %{ datetime: "Datetime", open: "Open", high: "High", low: "Low", close: "Close", volume: "Volume"},
      style: style,
      zoom: zoom,
      bull_color: bull_color,
      bear_color: bear_color,
      shadow_color: shadow_color,
      colorized_bars: colorized_bars,
      crisp_edges: true,
      body_border: true,
      timeframe: contex_timeframe( timeframe),
      domain_min: &domain_provider( &1, timeframe, domain_min, &2),
      overlays: [
        OHLC.MA.new( period: 5, color: "0000AA", width: 2)
      ]
    ]

    interval_count = Contex.OHLC.fixed_interval_count( opts ++ [ width: width])

    # Account for overlay lags
    { first, interval_count} =
      if domain_min do
        max_lag = Enum.reduce( opts[ :overlays], 0, &max( Overlayable.lag( &1), &2))

        { Utils.shift_datetime( timeframe, domain_min, -max_lag),
          interval_count + max_lag}
      else
        { min_date, interval_count}
      end

    dataset
    |> window( timeframe: timeframe, first: first, count: interval_count)
    |> Plot.new( Contex.OHLC, width, height, opts)
    |> Plot.to_svg()
  end

  @spec contex_timeframe( timeframe()) :: { atom(), non_neg_integer(), non_neg_integer()}
  defp contex_timeframe( timeframe)

  defp contex_timeframe( :d1), do: TimeScale.timeframe_d1()

  # Fetches domain_min while storing both domain min and max
  # with the Process
  @spec domain_provider( OHLC.t(), timeframe(), TimeScale.datetimes() | nil, non_neg_integer()) :: TimeScale.datetimes()
  defp domain_provider( ohlc, timeframe, domain_min, interval_count) do
    [ dataset, accessors] <~ ohlc.mapping

    first_dt = accessors.datetime.( List.first( dataset.data))
    last_dt = accessors.datetime.( List.last( dataset.data))

    new_domain_min =
      Contex.Utils.safe_max( first_dt, last_dt)
      |> then( &Utils.shift_datetime( timeframe, &1, -interval_count))
      |> Contex.Utils.safe_max( Contex.Utils.safe_min( first_dt, last_dt))
      |> tap( &Process.put( :chart_domain, %{ domain_min: &1, interval_count: interval_count}))

    domain_min || new_domain_min
  end

  # Extracts a list-based time window Dataset from an ETS-based Dataset.
  @spec window( Dataset.t(), keyword()) :: Dataset.t()
  defp window( dataset, opts) do
    [ timeframe | opts] <~ opts

    Dataset.update_data( dataset, fn table ->
      match_spec = ETS.time_window_spec( timeframe, opts)

      ETS.select( table, match_spec)
    end)
  end

  # Timeframe related

  @spec store_dataset( Socket.t(), ETS.table()) :: Socket.t()
  defp store_dataset( socket, table) do
    first_value = ETS.first_value( table)
    last_value = ETS.last_value( table)

    dataset = Dataset.new( [ first_value], ["Datetime", "Open", "High", "Low", "Close", "Volume"])
    accessor = Dataset.value_fn(dataset, "Datetime")
    min_date = accessor.( first_value)
    max_date = accessor.( last_value)
    dataset = Dataset.update_data( dataset, fn _ -> table end)

    socket
    |> assign( :dataset, dataset)
    |> assign( :min_date, min_date)
    |> assign( :max_date, max_date)
  end

  # Assigns

  # LiveView related
  defassignp :connected?

  # Chart display mechanics
  defassignp [ :width, :height, :chart]

  # Chart config
  defassignp [ :style, :bull_color, :bear_color, :shadow_color, :colorized_bars]

  # Dynamic chart settings
  defassignp [ :zoom, :timeframe, :domain_min, :interval_count]
end
