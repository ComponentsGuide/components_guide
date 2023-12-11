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

  def browser_keys(),
    do: [
      "chrome_android",
      "safari_ios",
      "samsunginternet_android",
      "firefox_android",
      "chrome",
      "safari",
      "firefox",
      "nodejs",
      "deno"
    ]

  def browsers(assigns) do
    ~H"""
    <div class="relative grid grid-cols-[max-content_auto] not-prose bg-white/5">
      <nav class="sticky flex flex-col text-left bg-white/5">
        <%= for key <- browser_keys() do %>
          <.link
            patch={~p"/browser-compat/browsers/#{key}"}
            aria-current={if @browser === key, do: "page", else: "false"}
            class="py-1 px-4 font-medium text-white aria-[current=page]:bg-blue-900"
          >
            <%= @browser_data[key]["name"] %>
          </.link>
        <% end %>
      </nav>
      <article class="">
        <%= if @browser_data[@browser] do %>
          <.browser key={@browser} data={@browser_data[@browser]} />
        <% end %>
      </article>
    </div>
    """
  end

  defp get_version_data(version_string) do
    version_string
    |> String.split(".")
    |> Enum.map(fn component ->
      case Integer.parse(component) do
        :error ->
          component

        other ->
          other
      end
    end)
  end

  def browser(assigns) do
    ~H"""
    <table class="w-full table-auto">
      <thead class="border-b border-b-white/5">
        <tr class="text-left">
          <th class="pl-6">Version</th>
          <th>Engine</th>
          <th>Release date</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        <%= for version <- Enum.sort_by(Map.keys(@data["releases"]), &get_version_data/1, :desc) do %>
          <tr>
            <td class="pl-6"><%= version %></td>
            <td><%= get_in(@data, ["releases", version, "engine"]) %> <%= get_in(@data, ["releases", version, "engine_version"]) %></td>
            <td><.link href={get_in(@data, ["releases", version, "release_notes"])}><%= get_in(@data, ["releases", version, "release_date"]) %></.link></td>
            <td><%= get_in(@data, ["releases", version, "status"]) %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    <%!-- <pre><%= inspect(@data, pretty: true) %></pre> --%>
    """
  end
end
