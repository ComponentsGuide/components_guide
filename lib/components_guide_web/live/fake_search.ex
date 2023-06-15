defmodule ComponentsGuideWeb.FakeSearchLive do
  use Phoenix.LiveView

  alias ComponentsGuide.FakeSearch

  def render(assigns) do
    ~L"""
    <div class="bg-white text-black">
      <p>UUID: <%= @uuid %></p>

      <form phx-change="suggest" phx-submit="search">
        <label>
          Search:
          <input name="q" value="<%= @query %>" class="border">
        </label>
      </form>

      <p><%= Enum.count(@filtered_items) %></p>

      <ul>
      <%= for item <- @filtered_items do %>
        <li><%= item["body"] %></li>
      <% end %>
      </ul>
    </div>
    """
  end

  defp new_uuid do
    Ecto.UUID.generate()
  end

  def mount(_, _session, socket) do
    # if connected?(socket), do: :timer.send_interval(5000, self(), :update)

    items = FakeSearch.list()

    {:ok, assign(socket, uuid: new_uuid(), items: items, filtered_items: items, query: "")}
  end

  def handle_info(:update, socket) do
    {:noreply, assign(socket, :uuid, new_uuid())}
  end

  def handle_event("suggest", %{"q" => query}, socket) when byte_size(query) <= 100 do
    items = socket.assigns.items

    filtered_items =
      Enum.filter(items, fn item ->
        String.contains?(item["body"], query)
      end)

    {:noreply, assign(socket, filtered_items: filtered_items)}
  end
end
