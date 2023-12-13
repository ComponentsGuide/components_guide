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
            class="py-1 px-4 font-medium text-white aria-[current=page]:bg-blue-900 border-l-2 border-transparent aria-[current=page]:border-blue-500"
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

  def list_detail(assigns) do
    ~H"""
    <div class="relative grid grid-cols-[max-content_auto] not-prose bg-white/5">
      <nav class="flex flex-col text-left bg-white/5">
        <filter-items class="contents" id={@id <> "-filter-items"} phx-update="ignore">
          <input
            type="search"
            placeholder="Filter"
            class="bg-black text-white border-0 px-4 font-mono"
            id={@id <> "-search"}
          />
          <phx-current-page class="contents">
            <%= render_slot(@nav_items) %>
          </phx-current-page>
        </filter-items>
      </nav>
      <article class="">
        <%= render_slot(@detail) %>
      </article>
    </div>
    """
  end

  defp decorate_secondary(primary, secondary)
  defp decorate_secondary("css-at-rules", secondary), do: "@" <> secondary
  defp decorate_secondary("css-selectors", secondary), do: ":" <> secondary
  defp decorate_secondary("css-types", secondary), do: secondary <> "()"
  defp decorate_secondary(_, secondary), do: secondary

  defp primary_to_path("css-" <> _), do: "css"
  defp primary_to_path(primary), do: primary

  def list_detail_nav_items(assigns) do
    ~H"""
    <%= for secondary <- Enum.sort_by(Map.keys(@data), &String.downcase/1), secondary = decorate_secondary(@primary, secondary) do %>
      <.link
        patch={~p"/browser-compat/#{primary_to_path(@primary)}/#{secondary}"}
        aria-current={if @secondary === secondary, do: "page", else: "false"}
        class="py-1 px-4 font-mono font-medium text-white aria-[current=page]:bg-blue-900 border-l-2 border-transparent aria-[current=page]:border-blue-500"
        data-filterable={secondary}
      >
        <%= secondary %>
      </.link>
    <% end %>
    """
  end

  def lookup_data("css-at-rules", "@" <> at_rule, data) when is_map_key(data, at_rule),
    do: at_rule

  def lookup_data("css-selectors", ":" <> selector, data) when is_map_key(data, selector),
    do: selector

  def lookup_data("css-properties", property, data) when is_map_key(data, property), do: property

  def lookup_data("css-types", secondary, data) do
    case String.replace_suffix(secondary, "()", "") do
      ^secondary -> nil
      type when is_map_key(data, type) -> type
      _ -> nil
    end
  end

  def lookup_data(_, _, _), do: nil

  def detail_entry(assigns) do
    ~H"""
    <%= if secondary = lookup_data(@primary, @secondary, @data) do %>
      <.html_entry primary={@primary} tag={secondary} data={@data[secondary]} />
    <% end %>
    """
  end

  def html_elements(assigns) do
    ~H"""
    <div class="relative grid grid-cols-[max-content_auto] not-prose bg-white/5">
      <nav class="flex flex-col text-left bg-white/5">
        <%= for tag <- Enum.sort_by(Map.keys(@html_data), &String.downcase/1) do %>
          <.link
            patch={~p"/browser-compat/#{@primary}/#{tag}"}
            aria-current={if @tag === tag, do: "page", else: "false"}
            class="py-1 px-4 font-mono font-medium text-white aria-[current=page]:bg-blue-900 border-l-2 border-transparent aria-[current=page]:border-blue-500"
          >
            <%= case @primary do
              "css-at-rules" -> "@" <> tag
              "css-selectors" -> ":" <> tag
              "css-types" -> tag <> "()"
              _ -> tag
            end %>
          </.link>
        <% end %>
      </nav>
      <article class="">
        <%= if @html_data[@tag] do %>
          <.html_entry primary={@primary} tag={@tag} data={@html_data[@tag]} />
        <% end %>
      </article>
    </div>
    """
  end

  defp html_main(primary, tag, key, map) do
    text =
      case {primary, key} do
        # "__compat" -> "<#{tag}>"
        {"css-at-rules", "__compat"} -> "@#{tag}"
        {_, "__compat"} -> tag
        {"html", key} -> "[#{key}]"
        {_, key} -> key
      end

    compat =
      case map do
        %{"__compat" => inner} -> inner
        map -> map
      end

    status =
      case compat do
        %{
          "status" => %{
            "deprecated" => deprecated?,
            "experimental" => experimental?,
            "standard_track" => standard_track?
          }
        } ->
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
          ^browser => %{"version_added" => true}
        }
      } ->
        "all"

      %{
        "support" => %{
          ^browser => %{"version_added" => version}
        }
      } ->
        version

      _ ->
        "?"
    end
  end

  def html_entry(assigns) do
    ~H"""
    <table class="w-full table-auto sticky top-0">
      <thead class="border-b border-b-white/5">
        <tr class="text-left">
          <th class="pl-6">Name</th>
          <th>Android Chrome</th>
          <th>iOS Safari</th>
          <th>Firefox</th>
          <th>Links</th>
        </tr>
      </thead>
      <tbody>
        <%= for key <- Enum.sort_by(Map.keys(@data), &String.downcase/1) do %>
          <tr>
            <td class="pl-6"><%= html_main(@primary, @tag, key, @data[key]) %></td>
            <td><%= html_browser_data("chrome_android", @data[key]) %></td>
            <td><%= html_browser_data("safari_ios", @data[key]) %></td>
            <td><%= html_browser_data("firefox", @data[key]) %></td>
            <td><%= html_links(@data[key]) %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
