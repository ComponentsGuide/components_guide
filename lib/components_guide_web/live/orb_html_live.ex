defmodule ComponentsGuideWeb.OrbHTMLLive do
  use Phoenix.LiveView
  use Phoenix.Component

  @impl true
  def render(assigns) do
    ~H"""
    UUID: <%= @uuid %>
    """
  end

  defp new_uuid do
    Ecto.UUID.generate()
  end

  @impl true
  def mount(%{}, _session, socket) do
    if connected?(socket), do: :timer.send_interval(5000, self(), :update)

    {:ok, assign(socket, uuid: new_uuid())}
  end

  @impl true
  def handle_info(:update, socket) do
    {:noreply, assign(socket, :uuid, new_uuid())}
  end
end
