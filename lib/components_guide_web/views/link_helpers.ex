defmodule ComponentsGuideWeb.LinkHelpers do
  use Phoenix.HTML

  def link(conn, text, opts) do
    to = Keyword.get(opts, :to)

    current =
      case conn.request_path do
        ^to -> "page"
        _ -> "false"
      end

    IO.inspect(%{
      current: current,
      request_path: conn.request_path,
      to: to
    })

    opts = Keyword.put(opts, :aria_current, current)

    Phoenix.HTML.Link.link(text, opts)
  end
end
