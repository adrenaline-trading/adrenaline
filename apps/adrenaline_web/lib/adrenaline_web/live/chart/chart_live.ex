defmodule AdrenalineWeb.Chart.ChartLive do
  use AdrenalineWeb, :live_view
  import Extructure
  alias Contex.{ Dataset, Plot, TimeScale, OHLC}
  alias Phoenix.LiveView.Socket

  @impl true
  def mount( _params, _session, socket) do
    socket =
      socket
      |> assign_chart( nil)
      |> assign_zoom( 3)
      |> assign_timeframe( :d1)
      |> assign_style( :candle)
      |> assign_bull_color( "00FF77")
      |> assign_bear_color( "FF3333")
      |> assign_shadow_color( "000000")
      |> assign_colorized_bars( false)
      |> assign_connected( connected?( socket))

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

  @spec zoom( Socket.t(), ( zoom -> boolean()), ( zoom -> zoom)) :: Socket.t() when zoom: 0..6
  defp zoom( socket, filter, updater) do
    [ zoom] <~ socket.assigns

    if filter.( zoom) do
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
    socket
  end

  defp handle_pane_event( "next-period", socket) do
    socket
  end

  defp handle_pane_event( "prev-page", socket) do
    socket
  end

  defp handle_pane_event( "next-page", socket) do
    socket
  end

  @spec recompute_chart( Socket.t()) :: Socket.t()
  defp recompute_chart( socket) do
    assign_chart( socket, generate_ohlc_svg( socket.assigns))
  end

  @spec generate_ohlc_svg( map()) :: Phoenix.HTML.safe()
  defp generate_ohlc_svg( args) do
    [ width, height, zoom, timeframe, style, bull_color, bear_color, shadow_color, colorized_bars] <~ args

    style = style == :bar && :tick || :candle
    bar_data = AdrenalineWeb.Chart.Data.data()
    dataset = Dataset.new( bar_data, ["Datetime", "Open", "High", "Low", "Close", "Volume"])

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
#      domain_min: ~N[2016-03-24 00:00:00],
      overlays: [
        OHLC.MA.new( period: 5, color: "0000AA", width: 2)
      ]
    ]

    Plot.new( dataset, Contex.OHLC, width, height, opts)
    |> Plot.to_svg()
  end

  # Timeframe related

  defp contex_timeframe( :d1), do: TimeScale.timeframe_d1()

  # Assigns

  # LiveView related
  defassignp :connected?

  # Chart display mechanics
  defassignp [ :width, :height, :chart]

  # Chart config
  defassignp [ :bull_color, :bear_color, :shadow_color, :colorized_bars]

  # Dynamic chart settings
  defassignp [ :zoom, :timeframe, :style]
end
