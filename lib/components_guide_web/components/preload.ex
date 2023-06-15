defmodule ComponentsGuideWeb.Preload do
  use Phoenix.Component

  def fetch(assigns) do
    ~H"""
    <link rel="preload" href={@href} as="fetch" crossorigin="anonymous" />
    """
  end
end
