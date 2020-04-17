defmodule ComponentsGuide.Research.Source do
  @cache_name :research_spec_cache

  defp read_cache(key) do
    tuple = {:ok, value} = Cachex.get(@cache_name, key)
    IO.puts("reading #{if value == nil, do: "nil", else: "present"}")
    IO.inspect(key)
    tuple
    # {:ok, nil}
  end

  defp write_cache(key, value) do
    Cachex.put(@cache_name, key, value)
  end

  defmodule Fetch do
    defstruct done: false, request_ref: nil, body_list: [], status: nil, headers: []

    defp apply_response({:status, _request_ref, status_code}, state = %Fetch{}) do
      %{state | status: status_code}
    end

    defp apply_response({:headers, _request_ref, headers}, state = %Fetch{}) do
      %{state | headers: headers}
    end

    defp apply_response({:data, _request_ref, chunk}, state = %Fetch{body_list: body_list}) do
      %{state | body_list: [body_list | [chunk]]}
    end

    defp apply_response({:done, _request_ref}, state = %Fetch{}) do
      %{state | done: true}
    end

    defp receive_mint_response(state = %Fetch{}, conn, request_ref) do
      receive do
        message ->
          case Mint.HTTP.stream(conn, message) do
            :unknown ->
              receive_mint_response(state, conn, request_ref)

            {:error, _, e, _} ->
              {:error, e}

            {:ok, conn, responses} ->
              state = Enum.reduce(responses, state, &apply_response/2)

              if state.done do
                {:ok, IO.iodata_to_binary(state.body_list)}
              else
                receive_mint_response(state, conn, request_ref)
              end
          end
      end
    end

    def get(url) do
      uri = URI.parse(url)

      IO.puts("fetching URL #{uri} #{uri.host} #{uri.path}")
      {:ok, conn} = Mint.HTTP.connect(:https, uri.host, 443)
      {:ok, conn, request_ref} = Mint.HTTP.request(conn, "GET", uri.path, [], nil)

      receive_mint_response(%Fetch{}, conn, request_ref)
    end
  end

  defp body({:fetch, url}) do
    IO.puts("fetching URL #{url}")
    # with {:ok, response} <- HTTPClient.get(url) do
    #   html = response.body
    #   {:ok, html}
    # end

    Fetch.get(url)

    # {:ok, response} = Mojito.request(method: :get, url: url, timeout: 50000)
    # {:ok, response.body}
  end

  defp body({:html_document, url}) do
    {:ok, html} = read({:fetch, url})
    tuple = {:ok, _document} = Floki.parse_document(html)
    tuple
  end

  defp body({:fetch_json, url}) do
    {:ok, encoded} = read({:fetch, url})
    tuple = {:ok, data} = Jason.decode(encoded)
    tuple
  end

  defp run(key) do
    tuple = {:ok, value} = body(key)
    write_cache(key, value)
    tuple
  end

  defp read(key) do
    case read_cache(key) do
      {:ok, nil} ->
        run(key)

      {:ok, value} ->
        {:ok, value}

      other ->
        other
    end
  end

  def html_document_at(url), do: read({:html_document, url})
  def json_at(url), do: read({:fetch_json, url})

  def clear_cache() do
    Cachex.clear(@cache_name)
  end
end
