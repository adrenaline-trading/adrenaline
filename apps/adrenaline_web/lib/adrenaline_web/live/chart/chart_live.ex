defmodule AdrenalineWeb.Chart.ChartLive do
  use AdrenalineWeb, :live_view
  import Extructure
  alias Contex.{ Dataset, Plot, TimeScale, OHLC}
  alias Phoenix.LiveView.Socket

  @typep timeframe() :: atom()

  @impl true
  def mount( _params, _session, socket) do
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
      |> assign_dataset( AdrenalineWeb.Chart.Data.data())

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

    shift_domain( socket, -1, &Contex.Utils.date_compare( &1, min_date) != :lt)
  end

  defp handle_pane_event( "next-period", socket) do
    [ max_date] <~ socket.assigns

    shift_domain( socket, 1, &Contex.Utils.date_compare( &1, max_date) != :gt)
  end

  defp handle_pane_event( "prev-page", socket) do
    socket
  end

  defp handle_pane_event( "next-page", socket) do
    socket
  end

  @spec shift_domain( Socket.t(), integer(), ( TimeScale.datetimes() -> boolean())) :: Socket.t()
  defp shift_domain( socket, shift, verifier) do
    [ domain_min, timeframe] <~ socket.assigns

    new_domain_min = shift_datetime( domain_min, timeframe, shift)

    if verifier.( new_domain_min) do
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

    socket
    |> assign_chart( generate_ohlc_svg( socket.assigns))
    |> then( & !domain_min && assign_domain_min( &1, Process.get( :domain_min)) || &1)
  end

  @spec generate_ohlc_svg( map()) :: Phoenix.HTML.safe()
  defp generate_ohlc_svg( args) do
    [ dataset,
      width, height,
      zoom, timeframe, _domain_min,
      style, bull_color, bear_color, shadow_color, colorized_bars] <~ args

    domain_min = domain_min || &domain_min( &1, timeframe, &2)
    style = style == :bar && :tick || :candle

    opts = [
      mapping: %{ datetime: "Datetime", open: "Open", high: "High", low: "Low", close: "Close"},
      style: style,
      zoom: zoom,
      bull_color: bull_color,
      bear_color: bear_color,
      shadow_color: shadow_color,
      colorized_bars: colorized_bars,
      crisp_edges: true,
      body_border: true,
      timeframe: contex_timeframe( timeframe),
      domain_min: domain_min,
      overlays: [
        OHLC.MA.new( period: 5, color: "0000AA", width: 2)
      ]
    ]

    Plot.new( dataset, Contex.OHLC, width, height, opts)
    |> Plot.to_svg()
  end

  @spec domain_min( OHLC.t(), timeframe(), non_neg_integer()) :: TimeScale.datetimes()
  defp domain_min( ohlc, timeframe, interval_count) do
    [ dataset, accessors] <~ ohlc.mapping

    first_dt = accessors.datetime.( List.first( dataset.data))
    last_dt = accessors.datetime.( List.last( dataset.data))

    Contex.Utils.safe_max( first_dt, last_dt)
    |> shift_datetime( timeframe, -interval_count)
    |> Contex.Utils.safe_max( Contex.Utils.safe_min( first_dt, last_dt))
    |> tap( &Process.put( :domain_min, &1))
  end

  # Timeframe related

  @spec shift_datetime( TimeScale.datetimes(), timeframe(), integer()) :: TimeScale.datetimes()
  defp shift_datetime( datetime, timeframe, shift) do
    { unit, _, _} = contex_timeframe( timeframe)

    Timex.shift( datetime, [ { unit, shift}])
  end

  @spec contex_timeframe( timeframe()) :: { atom(), non_neg_integer(), non_neg_integer()}
  defp contex_timeframe( timeframe)

  defp contex_timeframe( :d1), do: TimeScale.timeframe_d1()

  # Assigns

  defp assign_dataset( socket, bar_data) do
    dataset = Dataset.new( bar_data, ["Datetime", "Open", "High", "Low", "Close", "Volume"])
    { min_date, max_date} = Dataset.column_extents( dataset, "Datetime")

    socket
    |> assign( :dataset, dataset)
    |> assign( :min_date, min_date)
    |> assign( :max_date, max_date)
  end

  # LiveView related
  defassignp :connected?

  # Chart display mechanics
  defassignp [ :width, :height, :chart]

  # Chart config
  defassignp [ :style, :bull_color, :bear_color, :shadow_color, :colorized_bars]

  # Dynamic chart settings
  defassignp [ :zoom, :timeframe, :domain_min]
end
