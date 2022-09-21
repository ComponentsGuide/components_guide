defmodule ComponentsGuideWeb.ViewGithubRepoLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-6xl mx-auto text-lg text-white pb-24"}}

  alias ComponentsGuide.Fetch

  defmodule State do
    defstruct owner: "",
              repo: "",
              request: nil,
              response: nil

    def default() do
      %__MODULE__{
        owner: "JavaScriptRegenerated",
        repo: "yieldmachine"
        # owner: "facebook",
        # repo: "react"
      }
    end

    def add_response(
          %__MODULE__{} = state,
          request = %Fetch.Request{},
          response = %Fetch.Response{}
        ) do
      %__MODULE__{
        state
        | request: request,
          response: response
      }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.form
      let={f}
      for={:editor}
      id="view_source_form"
      phx-submit="submitted"
      class="max-w-2xl mt-12 mx-auto space-y-2"
    >

      <fieldset y-y y-stretch class="gap-1">
        <label for="owner">Owner:</label>
        <input id="owner" type="text" name="owner" value={@state.owner} class="text-black">
      </fieldset>

      <fieldset y-y y-stretch class="gap-1">
        <label for="repo">Repo name:</label>
        <input id="repo" type="text" name="repo" value={@state.repo} class="text-black">
      </fieldset>

      <div class="flex">
        <fieldset class="flex items-center gap-2">
          <label for="head-radio">
            <input id="head-radio" type="radio" name="method" value="HEAD" checked={true} />
            List Branches
          </label>

          <label for="get-radio">
            <input id="get-radio" type="radio" name="method" value="GET" checked={false} />
            Other
          </label>
        </fieldset>

        <span class="mx-auto"></span>
        <button type="submit" class="px-3 py-1 text-blue-100 bg-blue-600 rounded">Load</button>
      </div>
    </.form>

    <output form="view_source_form" class="prose prose-invert block pt-4 max-w-none text-center">
      <%= if @state.response do %>
        <pre><%= @state.request.method %> <%= @state.response.url %></pre>
        <p>
          Received <span class="px-2 py-1 bg-green-400 text-green-900 rounded"><%= @state.response.status %></span>
          in <%= System.convert_time_unit(@state.response.timings.duration, :native, :millisecond) %>ms
        </p>
        <view-source-filter>
          <form role="search" id="filter-results">
            <input name="q" type="search" placeholder="Filter results…" class="text-white bg-gray-800 border-gray-700 rounded">
          </form>
        </view-source-filter>
        <.headers_preview headers={@state.response.headers}>
        </.headers_preview>
        <%= if (@state.response.body || "") != "" do %>
          <.git_pkt_line_preview data={@state.response.body}>
          </.git_pkt_line_preview>
        <% end %>
      <% end %>
    </output>
    <style>
    dt[hidden] + dd {
      display: none;
    }
    </style>
    """
  end

  defp assign_state(socket, state) do
    assign(socket, state: state)
  end

  @impl true
  def mount(%{}, _session, socket) do
    state = State.default()
    socket = assign_state(socket, state)
    {:ok, socket}
  end

  @impl true
  def handle_event("changed", _form_values, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submitted", form_values, socket) do
    # state = State.from(form_values)
    IO.inspect(form_values)
    owner = Map.get(form_values, "owner")
    repo = Map.get(form_values, "repo")
    uri = URI.new!("https://github.com/owner/repo.git/info/refs?service=git-upload-pack")
    uri = put_in(uri.path, "/#{owner}/#{repo}.git/info/refs?service=git-upload-pack")
    # uri = put_in(uri.path, "/#{owner}/#{repo}.git/info/refs")
    IO.puts(uri |> URI.to_string())

    request =
      Fetch.Request.new(uri,
        headers: [
          {"Accept", "*/*"},
          {"User-Agent", "git/2.20.1"}
        ]
      )

    response = Fetch.load!(request)
    IO.inspect(response.headers)

    state = socket.assigns.state |> State.add_response(request, response)

    socket = socket |> assign_state(state)
    {:noreply, socket}
  end

  def headers_preview(assigns) do
    ~H"""
    <h2>Response Headers</h2>
    <dl class="grid grid-cols-2 gap-y-1 font-mono break-words">
      <%= for {name, value} <- @headers do %>
        <dt class="text-right font-bold"><%= name %></dt>
        <dd class="text-left pl-8"><%= value %></dd>
      <% end %>
    </dl>
    """
  end

  def hex_preview(assigns) do
    ~H"""
    <pre class="mx-auto p-0 max-w-[24ch] break-all whitespace-pre-wrap"><%= Base.encode16(@data) %></pre>
    """
  end

  def git_pkt_line_preview(assigns) do

    ~H"""
    <ul>
      <%= for pkt_line <- ComponentsGuide.Git.PktLine.decode(@data) do %>
        <li><%= inspect(pkt_line) %></li>
      <% end %>
    </ul>
    """
  end

  def list_html_features(html) do
    with {:ok, document} <- Floki.parse_document(html) do
      meta_values =
        for {"meta", attrs, _} <- Floki.find(document, "head meta"),
            key_value <- extract_meta_key_values(Map.new(attrs)) do
          key_value
        end

      link_values =
        for {"link", attrs, _} <- Floki.find(document, "head link"),
            key_value <- extract_link_key_values(Map.new(attrs)) do
          key_value
        end

      [meta_values: meta_values, link_values: link_values]
    else
      _ -> []
    end
  end

  def extract_link_key_values(%{"rel" => rel, "href" => href}) do
    [{rel, href}]
  end

  def extract_link_key_values(_) do
    []
  end

  def extract_meta_key_values(%{"name" => name, "content" => content}) do
    [{name, content}]
  end

  def extract_meta_key_values(%{"property" => property, "content" => content}) do
    [{property, content}]
  end

  def extract_meta_key_values(_), do: []
end
