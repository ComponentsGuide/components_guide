defmodule ComponentsGuideWeb.ActivityLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    UUID: <%= @uuid %>
    """
  end

  defp new_uuid do
    Ecto.UUID.generate
  end

  def mount(%{}, socket) do
    if connected?(socket), do: :timer.send_interval(5000, self(), :update)

    {:ok, assign(socket, uuid: new_uuid())}
  end

  def handle_info(:update, socket) do
    {:noreply, assign(socket, :uuid, new_uuid())}
  end
end
