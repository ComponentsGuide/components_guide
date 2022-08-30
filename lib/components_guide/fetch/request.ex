defmodule ComponentsGuide.Fetch.Request do
  defstruct method: "GET", url_string: "", uri: %URI{}, headers: [], body: nil

  def new!(url_string, options \\ []) do
    headers = Keyword.get(options, :headers, [])
    method = Keyword.get(options, :method, "GET")
    body = Keyword.get(options, :body)
    uri = URI.new!(url_string)
    %__MODULE__{method: method, url_string: url_string, uri: uri, headers: headers, body: body}
  end

  def new(url_string, options \\ []) do
    headers = Keyword.get(options, :headers, [])
    method = Keyword.get(options, :method, "GET")
    body = Keyword.get(options, :body)

    with {:ok, uri} <- URI.new(url_string) do
      {:ok,
       %__MODULE__{method: method, url_string: url_string, uri: uri, headers: headers, body: body}}
    else
      {:error, _} = value -> value
    end
  end
end
