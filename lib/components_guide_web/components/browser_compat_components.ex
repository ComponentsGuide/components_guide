defmodule ComponentsGuideWeb.BrowserCompatComponents do
  use ComponentsGuideWeb, :component

  defmodule HTMLElementLive do
    use ComponentsGuideWeb, :live_component

    def render(assigns) do
      ~H"""
      <details open={@open}>
        <summary phx-click="toggle" phx-target={@myself}><%= @title %></summary>
        <%= if @open do %>
          <pre><%= inspect(@data, pretty: true) %></pre>
        <% end %>
      </details>
      """
    end

    @impl true
    def mount(socket) do
      socket = socket |> assign(:open, false)
      {:ok, socket}
    end

    @impl true
    def handle_event("toggle", _, socket) do
      socket = update(socket, :open, &!/1)
      {:noreply, socket}
    end
  end

  # attr :date, Date, required: true
  attr :title, :string, required: true
  attr :tag, :string, required: true
  attr :data, :map, required: true

  # slot :cell_content

  def html_element(assigns) do
    ~H"""
    <.live_component module={HTMLElementLive} id={@tag} title={@title} data={@data} />
    """
  end
end
