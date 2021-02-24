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
    #{308, "Permanent Redirect", ""},
    
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
    {504, "Gateway Timeout", ""},
  ]
  
  @http_statuses_map Map.new(@http_statuses_list, fn {status, name, description} -> {"#{status}", {name, description}} end)
  
  @rfc_list [
    {"json", ["rfc8259", "rfc7159", "rfc4627"], "https://tools.ietf.org/html/rfc8259"},
  ]
  
  def search_for(query) when is_binary(query) do
    [
      search_for(:http_status, query)
    ]
  end

  defp search_for(:http_status, query) when is_binary(query) do
    query = query |> String.trim()
    case Map.get(@http_statuses_map, query) do
      nil ->
        nil
      
      {name, description} ->
        {:ok, name, description}
    end
  end
end
