defmodule AdrenalineWeb.Chart.ChartLive do
  use AdrenalineWeb, :live_view
  alias Contex.{ Dataset, Plot}

  @impl true
  def mount( _params, _session, socket) do
    bar_data = [
      [ ~N[2023-12-21 00:00:00], 55751860, 196.09, 196.63, 194.39, 195.89],
      [ ~N[2023-12-22 00:00:00], 40714050, 196.16, 196.95, 195.89, 196.94],
      [ ~N[2023-12-23 00:00:00], 52242820, 196.90, 197.68, 194.83, 194.83],
      [ ~N[2023-12-24 00:00:00], 46482550, 196.10, 197.08, 193.50, 194.68],
      [ ~N[2023-12-25 00:00:00], 37149570, 195.18, 195.41, 192.97, 193.60],
      [ ~N[2023-12-26 00:00:00], 28919310, 193.61, 193.89, 192.83, 193.05],
      [ ~N[2023-12-27 00:00:00], 48087680, 192.49, 193.50, 191.09, 193.15],
      [ ~N[2023-12-28 00:00:00], 34049900, 194.14, 194.66, 193.17, 193.58]
    ]

    dataset = Dataset.new( bar_data, ["Date", "Volume", "Open", "High", "Low", "Close"])

    opts = [
      mapping: %{ datetime: "Date", open: "Open", high: "High", low: "Low", close: "Close"},
      style: :candle,
      title: "AAPL",
      zoom: 3,
      bull_color: "00FF77",
      bear_color: "FF3333",
      shadow_color: "000000",
      crisp_edges: true,
      body_border: true
    ]

    chart_svg =
      Plot.new( dataset, Contex.OHLC, 1200, 800, opts)
      |> Plot.titles( "Sample Candlestick Chart", nil)
      |> Plot.to_svg()

    socket = assign( socket, :chart_svg, chart_svg)

    { :ok, socket}
  end
end
