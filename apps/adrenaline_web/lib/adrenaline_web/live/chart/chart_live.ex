defmodule AdrenalineWeb.Chart.ChartLive do
  use AdrenalineWeb, :live_view
  import Extructure
  alias Contex.{ Dataset, Plot, TimeScale, OHLC}

  @impl true
  def mount( _params, _session, socket) do
    socket =
      socket
      |> assign_chart( nil)
      |> assign( :connected?, connected?( socket))

    { :ok, socket}
  end

  @impl true
  def handle_event( "redraw", params, socket) do
    @[ width, height] <~ params

    socket =
      socket
      |> assign_width( String.to_integer( width))
      |> assign_height( String.to_integer( height))
      |> recompute_chart()

    { :noreply, socket}
  end

  @spec recompute_chart( Socket.t()) :: Socket.t()
  defp recompute_chart( socket) do
    [ width, height] <~ socket.assigns

    assign_chart( socket, generate_ohlc_svg( width, height))
  end

  @spec generate_ohlc_svg( non_neg_integer(), non_neg_integer()) :: Phoenix.HTML.safe()
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

  defassignp :width
  defassignp :height
  defassignp :chart
end
