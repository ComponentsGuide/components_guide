defmodule ComponentsGuide.Research.Static do
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
    {"WebSockets", ["rfc6455"], []}
  ]

  @aliases %{
    "redirect" => ["301", "302"],
    "invalid" => ["412", "422"],
    "etag" => ["304"]
  }

  def search_for(query) when is_binary(query) do
    [
      search_for(:http_status, query),
      search_for(:rfc, query)
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
end
