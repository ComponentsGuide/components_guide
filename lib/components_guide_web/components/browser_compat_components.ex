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

  @browser_keys [
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

  def browser_keys(), do: @browser_keys

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
            <td>
              <%= get_in(@data, ["releases", version, "engine"]) %> <%= get_in(@data, [
                "releases",
                version,
                "engine_version"
              ]) %>
            </td>
            <td>
              <.link href={get_in(@data, ["releases", version, "release_notes"])}>
                <%= get_in(@data, ["releases", version, "release_date"]) %>
              </.link>
            </td>
            <td><%= get_in(@data, ["releases", version, "status"]) %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    <%!-- <pre><%= inspect(@data, pretty: true) %></pre> --%>
    """
  end

  def html(assigns) do
    ~H"""
    <div class="relative grid grid-cols-[max-content_auto] not-prose bg-white/5">
      <nav class="flex flex-col text-left bg-white/5">
        <%= for tag <- Enum.sort(Map.keys(@html_data["elements"])) do %>
          <.link
            patch={~p"/browser-compat/html/#{tag}"}
            aria-current={if @tag === tag, do: "page", else: "false"}
            class="py-1 px-4 font-mono font-medium text-white aria-[current=page]:bg-blue-900 border-l-2 border-transparent aria-[current=page]:border-blue-500"
          >
            <%= tag %>
          </.link>
        <% end %>
      </nav>
      <article class="">
        <%= if @html_data["elements"][@tag] do %>
          <.html_entry tag={@tag} data={@html_data["elements"][@tag]} />
        <% end %>
      </article>
    </div>
    """
  end

  defp html_main(tag, key, map) do
    text = case key do
      # "__compat" -> "<#{tag}>"
      "__compat" -> tag
      key -> "[#{key}]"
    end

    compat =
      case map do
        %{"__compat" => inner} -> inner
        map -> map
      end

    status = case compat do
      %{"status" => %{
        "deprecated" => deprecated?,
        "experimental" => experimental?,
        "standard_track" => standard_track?
      }} ->
        cond do
          deprecated? -> "deprecated"
          experimental? -> "experimental"
          true -> ""
        end

      _ ->
        ""
    end

    case status do
      "" ->
        content_tag(:span, [text], class: "font-mono")

      status ->
        content_tag(:span, [
          content_tag(:span, [text], class: "font-mono"),
          " · ",
          content_tag(:i, status)
        ])
    end
  end

  defp html_links(assigns) do
    ~H"""
    <%= if assigns["mdn_url"] do %>
      <.link href={assigns["mdn_url"]}>MDN</.link>
    <% end %>
    <%= if assigns["spec_url"] do %>
      <.link href={assigns["spec_url"]}>Spec</.link>
    <% end %>
    """
  end

  defp html_spec_url(map) do
    case map do
      %{"spec_url" => spec_url} ->
        spec_url

      _ ->
        nil
    end
  end

  defp html_browser_data(browser, map) when browser in @browser_keys do
    compat =
      case map do
        %{"__compat" => inner} -> inner
        map -> map
      end

    case compat do
      %{
        "support" => %{
          ^browser => %{"version_added" => false}
        }
      } ->
        "–"

      %{
        "support" => %{
          ^browser => %{"version_added" => version}
        }
      } ->
        version

      _ ->
        "–"
    end
  end

  def html_entry(assigns) do
    ~H"""
    <table class="w-full table-auto sticky top-0">
      <thead class="border-b border-b-white/5">
        <tr class="text-left">
          <th class="pl-6">Tag/Attribute</th>
          <th>Android Chrome</th>
          <th>iOS Safari</th>
          <th>Firefox</th>
          <th>Links</th>
        </tr>
      </thead>
      <tbody>
        <%= for key <- Map.keys(@data) do %>
          <tr>
            <td class="pl-6"><%= html_main(@tag, key, @data[key]) %></td>
            <td><%= html_browser_data("chrome_android", @data[key]) %></td>
            <td><%= html_browser_data("safari_ios", @data[key]) %></td>
            <td><%= html_browser_data("firefox", @data[key]) %></td>
            <td><%= html_links(@data[key]) %></td>
            <%!-- <td><%= get_in(@data, ["releases", version, "engine"]) %> <%= get_in(@data, ["releases", version, "engine_version"]) %></td>
            <td><%= get_in(@data, ["releases", version, "status"]) %></td> --%>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
