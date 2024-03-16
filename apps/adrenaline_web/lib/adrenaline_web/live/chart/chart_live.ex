defmodule AdrenalineWeb.Chart.ChartLive do
  use AdrenalineWeb, :live_view
  import Extructure
  alias Contex.{ Dataset, Plot, TimeScale, OHLC}

  @impl true
  def mount( _params, _session, socket) do
    socket =
      socket
      |> assign( :chart_svg, nil)
      |> assign( :connected?, connected?( socket))

    { :ok, socket}
  end

  @impl true
  def handle_event( "redraw", params, socket) do
    @[ width, height] <~ params

    socket =
      socket
      |> assign( :width, String.to_integer( width))
      |> assign( :height, String.to_integer( height))
      |> recompute_chart()

    { :noreply, socket}
  end

  defp recompute_chart( socket) do
    [ width, height] <~ socket.assigns

    chart_svg = generate_ohlc_svg( width, height);
    assign( socket, :chart_svg, chart_svg)
  end

  defp generate_ohlc_svg( width, height) do
    bar_data = AdrenalineWeb.Chart.Data.data()
    dataset = Dataset.new( bar_data, ["Date", "Open", "High", "Low", "Close", "Volume"])

    opts = [
      mapping: %{ datetime: "Date", open: "Open", high: "High", low: "Low", close: "Close"},
      style: :candle,
      zoom: 3,
      bull_color: "00FF77",
      bear_color: "FF3333",
      shadow_color: "000000",
      crisp_edges: true,
      body_border: true,
      timeframe: TimeScale.timeframe_d1(),
#      domain_min: ~N[2016-03-24 00:00:00],
      overlays: [
        OHLC.MA.new( period: 5, color: "0000AA", width: 2)
      ]
    ]

    Plot.new( dataset, Contex.OHLC, width, height, opts)
    |> Plot.to_svg()
  end
end
