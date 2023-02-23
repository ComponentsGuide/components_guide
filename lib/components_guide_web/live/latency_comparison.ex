defmodule ComponentsGuideWeb.LatencyComparisonLive do
  use ComponentsGuideWeb,
      {:live_view, container: {:div, class: "max-w-6xl mx-auto text-lg text-white pb-24"}}

  alias ComponentsGuide.Fetch

  defmodule State do
    defstruct responses: nil, form_values: %{}

    def default() do
      %__MODULE__{}
    end

    def add_responses(
          %__MODULE__{} = state,
          responses = [%Fetch.Response{} | _]
        ) do
      %__MODULE__{
        state
        | responses: responses
      }
    end

    def set_form_values(%__MODULE__{} = state, form_values = %{}) do
      %__MODULE__{
        state
        | form_values: form_values
      }
    end

    def get_fastest_slowest_responses(%__MODULE__{responses: nil}), do: nil

    def get_fastest_slowest_responses(%__MODULE__{responses: responses}) do
      Enum.min_max_by(responses, fn response -> response.timings.duration end)
    end

    def get_headers_of_interest(%Fetch.Response{} = response) do
      h = response.headers
      location = Enum.find(h, fn {key, _} -> String.downcase(key) == "location" end)
      content_length = Enum.find(h, fn {key, _} -> String.downcase(key) == "content-length" end)
      content_encoding = Enum.find(h, fn {key, _} -> String.downcase(key) == "content_encoding" end)
      transfer_encoding = Enum.find(h, fn {key, _} -> String.downcase(key) == "transfer-encoding" end)
      cache_control = Enum.find(h, fn {key, _} -> String.downcase(key) == "cache-control" end)
      server = Enum.find(h, fn {key, _} -> String.downcase(key) == "server" end)
      cf_ray = Enum.find(h, fn {key, _} -> String.downcase(key) == "cf-ray" end)
      inspect([
        location,
        content_length,
        content_encoding,
        transfer_encoding,
        cache_control,
        server,
        cf_ray
      ] |> Enum.filter(fn v -> v != nil end))
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <nav class="pt-8 pb-8">
      <ul class="list-none flex justify-center gap-4">
        <li><.link href="/latency-comparison/cdns">CDNs</.link></li>
        <li><.link href="/latency-comparison/dev-blogs">Dev Blogs</.link></li>
        <li><.link href="/latency-comparison/robots.txt">Robots.txt</.link></li>
        <li><.link href="/latency-comparison/edge">Edge</.link></li>
      </ul>
    </nav>
    <.form
      for={:editor}
      id="latency_comparison_form"
      phx-submit="submitted"
      class="max-w-2xl mx-auto space-y-2"
    >
      <div class="flex flex-col items-center gap-4">
        <button type="submit" class="px-3 py-1 text-xl text-blue-900 bg-blue-200 rounded" autofocus>Load</button>
        <input type="url" id="user_url" name="user_url" value={@state.form_values["user_url"]} class="w-80 text-sm text-white bg-black border border-gray-700 rounded" placeholder="Compare your URL (optional)" aria-label="">
      </div>
    </.form>

    <output form="latency_comparison_form" class="flex flex-col gap-4 pt-4 max-w-none text-center">
      <%= for response <- @state.responses || [], response != nil do %>
        <div class="p-4 text-white bg-black font-mono">
          <pre class="bg-transparent" title={State.get_headers_of_interest(response)}><%= response.url %></pre>
          <div class="my-1 flex justify-center">
            <div class="h-1 bg-yellow-200" style={"width: #{System.convert_time_unit(response.timings.connected, :native, :millisecond)}px"}></div>
            <div class="h-1 bg-green-500" style={"width: #{System.convert_time_unit(response.timings.received_status - response.timings.connected, :native, :millisecond)}px"}></div>
            <div class="h-1 bg-purple-200" style={"width: #{System.convert_time_unit(response.timings.duration - response.timings.received_status, :native, :millisecond)}px"}></div>
          </div>
          <p class="flex justify-center items-center gap-3 text-lg">
            <data class="text-yellow-200"><%= System.convert_time_unit(response.timings.connected, :native, :millisecond) %>ms</data> <span>🤝</span>
            <span class="text-blue-200/75">+</span> <data class="text-green-200"><%= System.convert_time_unit(response.timings.received_status - response.timings.connected, :native, :millisecond) %>ms</data> <span class="px-1 text-sm text-green-900 bg-green-100 border border-green-200 rounded-full"><%= response.status %></span>
            <span class="text-blue-200/75">+</span> <data class="text-purple-200"><%= System.convert_time_unit(response.timings.duration - response.timings.received_status, :native, :millisecond) %>ms</data> <span class="px-1 text-sm text-purple-900 bg-purple-100 border border-purple-200 rounded-full"><%= Format.humanize_bytes(byte_size(response.body)) %></span>
            <span class="text-blue-200/75">=</span> <data class="text-blue-200"><%= System.convert_time_unit(response.timings.duration, :native, :millisecond) %>ms</data>
          </p>
        </div>
      <% end %>
      <%= if tuple = State.get_fastest_slowest_responses(@state) do %>
        <% {fastest, slowest} = tuple %>
        <ul class="list-none">
          <li>Fastest is <%= fastest.url %> in <data><%= System.convert_time_unit(fastest.timings.duration, :native, :millisecond) %>ms</data></li>
          <li>Slowest is <%= slowest.url %> in <data><%= System.convert_time_unit(slowest.timings.duration, :native, :millisecond) %>ms</data></li>
        </ul>
      <% end %>
    </output>
    """
  end

  defp assign_state(socket, state), do: assign(socket, state: state)

  @impl true
  def mount(params, _session, socket) do
    socket = assign(socket, page_title: "Latency Comparison")

    section = Map.get(params, "section")
    default_urls = default_urls(section)

    state = State.default()

    socket =
      socket
      |> assign_state(state)
      |> assign(:default_urls, default_urls)

    {:ok, socket}
  end

  @impl true
  def handle_event("submitted", form_values = %{"user_url" => user_url}, socket) do
    urls = socket.assigns[:default_urls]

    urls =
      case URI.new(user_url) do
        {:ok, %URI{host: ""}} -> urls
        {:ok, uri = %URI{host: host, port: 443}} when is_binary(host) -> [to_string(uri) | urls]
        _ -> urls
      end

    responses =
      for url <- urls do
        req = Fetch.Request.new!(url)
        Fetch.load!(req)
      end

    # redis_timings = Fetch.Timings.start()
    # {duration_microseconds, _result} =
    #   :timer.tc(fn ->
    #     case Redix.command(:redix_cache, ["GET", "whatever"]) do
    #       {:ok, value} -> value
    #       _ -> nil
    #     end
    #   end)
    # redis_timings = Fetch.Timings.finish(redis_timings)
    # redis_res = Fetch.Response.new("redis:") |> Fetch.Response.add_timings(redis_timings)
    # responses = [redis_res | responses]

    state =
      socket.assigns.state
      |> State.add_responses(responses)
      |> State.set_form_values(form_values)

    socket = socket |> assign_state(state)
    {:noreply, socket}
  end

  def default_urls("dev-blogs") do
    [
      "https://aws.amazon.com/blogs/aws/",
      "https://aws.amazon.com/blogs/aws/feed/",
      "https://cloud.google.com/blog/",
      "https://github.blog/",
      "https://github.blog/feed/",
      "https://blog.cloudflare.com/",
      "https://blog.cloudflare.com/rss/",
      "https://vercel.com/blog",
      "https://vercel.com/atom",
      "https://tailwindcss.com/blog",
      "https://tailwindcss.com/feeds/atom.xml",
      "https://fly.io/blog/",
      "https://fly.io/blog/feed.xml",
      "https://render.com/blog",
      "https://render.com/blog/rss.xml"
    ]
  end

  def default_urls("robots.txt") do
    [
      "https://github.com/robots.txt",
      "https://www.youtube.com/robots.txt",
      "https://medium.com/robots.txt",
      "https://twitter.com/robots.txt",
      "https://instagram.com/robots.txt",
      "https://www.apple.com/robots.txt",
      "https://www.cloudflare.com/robots.txt",
      "https://unpkg.com/robots.txt",
      "https://vercel.com/robots.txt",
      "https://render.com/robots.txt"
    ]
  end

  def default_urls("cdns") do
    [
      "https://cdn.jsdelivr.net/npm/underscore@1.13.6/underscore-esm-min.js",
      "https://unpkg.com/underscore@1.13.6/underscore-esm-min.js",
      "https://esm.sh/v107/underscore@1.13.6/es2021/underscore.js",
      "https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.13.6/underscore-esm-min.min.js"
    ]
  end

  def default_urls("edge") do
    [
      "https://workers.cloudflare.com/cf.json",
      "https://components-guide.collected.workers.dev/cf.json",
      "https://components-guide.deno.dev/cf.json",
      "https://components-guide.collected.workers.dev/time",
      "https://components-guide.deno.dev/time",
      "https://components-guide.collected.workers.dev/deno/time",
      "https://components-guide.deno.dev/cf/time",
      "https://cdn.jsdelivr.net/npm/underscore@1.13.6/underscore-esm-min.js",
      "https://components-guide.collected.workers.dev/cdn.jsdelivr.net/npm/underscore@1.13.6/underscore-esm-min.js",
      "https://components-guide.deno.dev/cdn.jsdelivr.net/npm/underscore@1.13.6/underscore-esm-min.js",
      "https://unpkg.com/underscore@1.13.6/underscore-esm-min.js",
      "https://components-guide.collected.workers.dev/unpkg.com/underscore@1.13.6/underscore-esm-min.js",
      "https://components-guide.deno.dev/unpkg.com/underscore@1.13.6/underscore-esm-min.js",
    ]
  end

  def default_urls(_) do
    [
      "https://workers.cloudflare.com/cf.json",
      "https://api.github.com/rate_limit",
      "https://unpkg.com/robots.txt",
      "https://api.npmjs.org/downloads/point/last-month/react",
      "https://cdn.jsdelivr.net/npm/underscore@1.13.6/underscore-esm-min.js",
      "https://unpkg.com/underscore@1.13.6/underscore-esm-min.js",
    ]
  end
end
