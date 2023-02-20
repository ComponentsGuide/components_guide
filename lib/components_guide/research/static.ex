defmodule ComponentsGuide.Research.Static do
  alias ComponentsGuide.Fetch

  @http_statuses_list [
    {101, "Switching Protocols", ""},
    {200, "OK", ""},
    {201, "Created", ""},
    {202, "Accepted", ""},
    {204, "No Content", ""},
    {301, "Moved Permanently", ""},
    {302, "Found", ""},
    {303, "See Other", ""},
    {304, "Not Modified", ""},
    {307, "Temporary Redirect", ""},
    # {308, "Permanent Redirect", ""},

    {400, "Bad Request", ""},
    {401, "Unauthorized", ""},
    {402, "Payment Required", ""},
    {403, "Forbidden", ""},
    {404, "Not Found", ""},
    {405, "Method Not Allowed", ""},
    {406, "Not Acceptable", ""},
    {409, "Conflict", ""},
    {410, "Gone", ""},
    {412, "Precondition Failed", ""},
    {422, "Unprocessable Entity", ""},
    {429, "Too Many Requests", ""},
    {500, "Internal Server Error", ""},
    {501, "Not Implemented", ""},
    {502, "Bad Gateway", ""},
    {503, "Service Unavailable", ""},
    {504, "Gateway Timeout", ""}
  ]

  @http_statuses_map Map.new(@http_statuses_list, fn {status, name, description} ->
                       {"#{status}", {name, description}}
                     end)

  @rfc_list [
    {"UTF-8", ["rfc3629"], []},
    {"JSON", ["rfc8259", "rfc7159", "rfc4627"],
     [
       media_type: "application/json"
     ]},
    {"CSV", ["rfc4180"],
     [
       media_type: "text/csv"
     ]},
    {"URL", ["rfc1738"], []},
    {"URI", ["rfc3986"], []},
    {"TCP", ["rfc793"], []},
    {"UDP", ["rfc768"], []},
    {"DNS", ["rfc1034", "rfc1035"], []},
    {"DNS TXT", ["rfc1464"], []},
    {"HTTP", ["rfc2616", "rfc7230", "rfc7231", "rfc7232", "rfc7233", "rfc7234", "rfc7235"], []},
    {"Timestamps", ["rfc3339", "ISO 8601"], []},
    {"WebSockets", ["rfc6455"], []},
    {"DNS-Based Service Discovery", ["rfc6763"], []}
  ]

  @icon_names [
                "acast",
                "access",
                "adobe",
                "airbnb",
                "amazon",
                "amazon_alexa",
                "amazon_s3",
                "amberframework",
                "andotp",
                "android",
                "angellist",
                "angular",
                "ansible",
                "apereo",
                "apple",
                "apple_music",
                "arch_linux",
                "auth0",
                "authy",
                "backbone",
                "badoo",
                "baidu",
                "bandcamp",
                "behance",
                "bing",
                "bitbucket",
                "bitcoin",
                "bitwarden",
                "blogger",
                "bluetooth",
                "buffer",
                "calendar",
                "centos",
                "chrome",
                "chromium",
                "clojure",
                "cloudflare",
                "codeberg",
                "codepen",
                "coffeescript",
                "coil",
                "coinpot",
                "crystal",
                "debian",
                "deezer",
                "delicious",
                "dev_to",
                "digidentity",
                "digitalocean",
                "discord",
                "disqus",
                "djangoproject",
                "docker",
                "dribbble",
                "drone",
                "dropbox",
                "drupal",
                "duckduckgo",
                "ea",
                "ebay",
                "edge",
                "element",
                "elementaryos",
                "email",
                "epub",
                "espressif",
                "ethereum",
                "evernote",
                "facebook",
                "finder",
                "firefox",
                "flattr",
                "flickr",
                "flutter",
                "freecodecamp",
                "friendica",
                "fritz",
                "gandi",
                "gatehub",
                "ghost",
                "git",
                "gitea",
                "github",
                "gitlab",
                "glitch",
                "gmail",
                "gmail_old",
                "go",
                "gogcom",
                "gojek",
                "goodreads",
                "google",
                "google_calendar",
                "google_collaborative_content_tools",
                "google_docs_editors",
                "google_drive",
                "google_drive_old",
                "google_maps",
                "google_maps_old",
                "google_meet",
                "google_play",
                "google_plus",
                "google_podcasts",
                "google_scholar",
                "gradle",
                "grafana",
                "hackernews",
                "hackerone",
                "haml",
                "heroku",
                "homekit",
                "hp",
                "html5",
                "humblebundle",
                "ibm",
                "iheartradio",
                "imdb",
                "imgur",
                "instagram",
                "intel",
                "internet_archive",
                "itch_io",
                "itunes_podcasts",
                "java",
                "javascript",
                "jellyfin",
                "json",
                "julia",
                "kaggle",
                "keepassdx",
                "kemal",
                "keskonfai",
                "keybase",
                "kickstarter",
                "ko-fi",
                "kodi",
                "kotlin",
                "laravel",
                "lastpass",
                "liberapay",
                "line",
                "linkedin",
                "linux",
                "linux_mint",
                "lock",
                "luckyframework",
                "macos",
                "mail",
                "mailchimp",
                "markdown",
                "mastodon",
                "mattermost",
                "medium",
                "meetup",
                "messenger",
                "microformats",
                "microsoft",
                "minecraft",
                "nextcloud",
                "nhs",
                "npm",
                "ok",
                "openbenches",
                "openbugbounty",
                "opencast",
                "opencollective",
                "opencores",
                "opensource",
                "openvpn",
                "opera",
                "orcid",
                "overcast",
                "patreon",
                "paypal",
                "pdf",
                "phone",
                "php",
                "pinboard",
                "pinterest",
                "pixelfed",
                "plex",
                "pocket",
                "pocketcasts",
                "preact",
                "print",
                "protonmail",
                "python",
                "qq",
                "raspberry_pi",
                "react",
                "reddit",
                "redhat",
                "researchgate",
                "roundcube",
                "rss",
                "ruby",
                "rubygems",
                "rubyonrails",
                "rust",
                "safari",
                "samsung",
                "samsung_internet",
                "samsung_s",
                "samsung_swoop",
                "sass",
                "semaphoreci",
                "sentry",
                "signal",
                "sketch",
                "skype",
                "slack",
                "slideshare",
                "snapchat",
                "soundcloud",
                "spotify",
                "square_cash",
                "stackexchange",
                "stackoverflow",
                "steam",
                "stitcher",
                "strava",
                "stumbleupon",
                "svelte",
                "svg",
                "svgo.yml",
                "symantec",
                "taiga",
                "teamspeak",
                "telegram",
                "threema",
                "tiktok",
                "tox",
                "trello",
                "tripadvisor",
                "tumblr",
                "tunein",
                "tutanota",
                "twilio",
                "twitch",
                "twitter",
                "uber",
                "ubiquiti",
                "ubisoft",
                "ubuntu",
                "unicode",
                "untappd",
                "uphold",
                "uplay",
                "upwork",
                "vegetarian",
                "venmo",
                "viber",
                "vimeo",
                "vivino",
                "vk",
                "vlc",
                "vue",
                "w3c",
                "wechat",
                "wekan",
                "whatsapp",
                "wifi",
                "wikipedia",
                "windows",
                "wire",
                "wireguard",
                "wordpress",
                "workato",
                "xing",
                "xmpp",
                "yahoo",
                "yammer",
                "yarn",
                "yelp",
                "youtube",
                "yubico",
                "zoom"
              ]
              |> MapSet.new()

  defmodule Sources do
    @cache_enabled true
    @cache_name :static_sources_cache

    def cache_name(), do: @cache_name

    defp read_cache(key) do
      if @cache_enabled do
        {:ok, value} = Cachex.get(@cache_name, key)
        value
      else
        nil
      end
    end

    defp write_cache(key, value) do
      if @cache_enabled do
        Cachex.put(@cache_name, key, value)
      end
    end

    def fetch_simple_icon_names() do
      url = "https://unpkg.com/browse/simple-icons@8.5.0/icons/"

      case cached = read_cache(url) do
        nil ->
          link_els =
            Fetch.get!(url).body
            |> Floki.parse_document!()
            |> Floki.find("table tbody td a")

          names = for {"a", _attrs, [text]} <- link_els, text != "..", do: text
          names = MapSet.new(names)
          write_cache(url, names)
          names

        names ->
          names
      end
    end
  end

  @simple_icons ComponentsGuide.Research.Static.Sources.fetch_simple_icon_names()

  @aliases %{
    "redirect" => ["301", "302"],
    "invalid" => ["412", "422"],
    "etag" => ["304"]
  }

  def search_for(query) when is_binary(query) do
    [
      search_for(:http_status, query),
      search_for(:rfc, query),
      search_for(:super_tiny_icon, query),
      search_for(:simple_icons, query)
    ]
    |> List.flatten()
  end

  defp search_for(:http_status, query) when is_binary(query) do
    query = query |> String.trim()

    case Map.get(@http_statuses_map, query) do
      nil ->
        []

      {name, description} ->
        [{:http_status, {name, description}}]
    end
  end

  defp search_for(:rfc, query) when is_binary(query) do
    query = query |> String.downcase() |> String.trim()

    matches? = fn
      {^query, _, _} ->
        true

      {name, rfcs, metadata} ->
        String.downcase(name) == query ||
          Enum.member?(rfcs, query) ||
          Keyword.get(metadata, :media_type) == query
    end

    @rfc_list
    |> Stream.filter(matches?)
    |> Enum.map(fn item -> {:rfc, item} end)
  end

  defp search_for(:super_tiny_icon, query) when is_binary(query) do
    query = query |> String.downcase() |> String.trim()

    case MapSet.member?(@icon_names, query) do
      true ->
        [
          {:super_tiny_icon,
           %{
             name: query,
             url: "https://cdn.jsdelivr.net/npm/super-tiny-icons@0.4.0/images/svg/#{query}.svg",
             urls: [
               "https://cdn.jsdelivr.net/npm/super-tiny-icons@0.4.0/images/svg/#{query}.svg",
               "https://unpkg.com/super-tiny-icons@0.4.0/images/svg/#{query}.svg"
             ]
           }}
        ]

      false ->
        []
    end
  end

  defp search_for(:simple_icons, query) when is_binary(query) do
    query = query |> String.downcase() |> String.trim()
    names = ComponentsGuide.Research.Static.Sources.fetch_simple_icon_names()
    # names = @simple_icons

    case MapSet.member?(names, query <> ".svg") do
      true ->
        [
          {:simple_icon,
           %{
             name: query,
             url: "https://cdn.jsdelivr.net/npm/simple-icons@8.5.0/icons/#{query}.svg",
             urls: [
               "https://cdn.jsdelivr.net/npm/simple-icons@8.5.0/icons/#{query}.svg",
               "https://unpkg.com/simple-icons@8.5.0/icons/#{query}.svg"
             ]
           }}
        ]

      false ->
        []
    end
  end
end
