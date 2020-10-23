defmodule ComponentsGuideWeb.WebStandards.Live.HttpCaching do
  use ComponentsGuideWeb, :live_view
  alias ComponentsGuideWeb.StylingHelpers

  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: %{})}
  end

  def render(assigns) do
    ~L"""
    <p>Hello!</p>
    """
  end
end
