defmodule ComponentsGuide.Research.Source do
  alias ComponentsGuide.Fetch

  @cache_enabled true
  @cache_read_from_redis true

  @cache_name :research_spec_cache

  defp read_cache(key) do
    if @cache_enabled do
      tuple = {:ok, value} = Cachex.get(@cache_name, key)
      IO.puts("reading #{if value == nil, do: "nil", else: "present"}")
      IO.inspect(key)
      tuple
    else
      {:ok, nil}
    end
  end

  defp write_cache(key, value) do
    if @cache_enabled do
      Cachex.put(@cache_name, key, value)
    end
  end

  defp read_redis_cache(key) do
    {duration_microseconds, result} =
      :timer.tc(fn ->
        case Redix.command(:redix_cache, ["GET", key]) do
          {:ok, value} -> value
          _ -> nil
        end
      end)

    IO.puts("read from redis #{key} in #{duration_microseconds} microseconds")
    IO.inspect(result)
    result
  end

  defp write_redis_cache(key, value) do
    result = Redix.command(:redix_cache, ["SET", key, value])
    IO.inspect(result, label: "Redis write")
  end

  defp run({:fetch_text, url}) do
    IO.puts("fetching URL #{url}")

    response = Fetch.get!(url)

    case response.status do
      200 ->
        {:ok, response.body}

      status ->
        {:error, {:http_status, status, response.body}}
    end
  end

  defp run({:html_document, url}) do
    with {:ok, text} <- read({:fetch_text, url}),
         {:ok, document} <- Floki.parse_document(text) do
      {:ok, document}
    else
      _ -> :error
    end
  end

  # TODO: Use a Source.FetchJSON module instead that conforms to a particular behavior
  defp run({:fetch_json, url}) do
    with {:ok, text} when not is_nil(text) <- read({:fetch_text, url}),
         {:ok, data} <- Jason.decode(text) do
      {:ok, data}
    else
      other -> other
    end
  end

  defp run({:content_length, url}) do
    with {:ok, req} <- Fetch.Request.new(url),
         %Fetch.Response{headers: headers} = Fetch.load!(req),
         {_, s} <-
           Enum.find(headers, fn {key, _} -> String.downcase(key) == "content-length" end),
         {n, _} <- Integer.parse(s) do
      {:ok, n}
    else
      _ -> :error
    end
  end

  defp cache_key(key) when is_binary(key) do
    :crypto.hash(:sha256, key) |> Base.encode16(case: :lower)
  end

  defp run_and_cache(key) do
    with {:ok, value} <- run(key) do
      write_cache(key, value)

      case key do
        {:fetch_text, url} ->
          IO.puts("Writing to redis #{url}")
          write_redis_cache(url, value)
          # write_rest_redis_cache(url, value)

        _ ->
          nil
      end

      {:ok, value}
    else
      other ->
        write_cache(key, :error)
        other
    end
  end

  defp should_read_url_from_redis("https://cdn.jsdelivr.net/" <> _), do: false
  defp should_read_url_from_redis(_url), do: @cache_read_from_redis

  defp read(key) do
    case read_cache(key) do
      {:ok, nil} ->
        from_redis =
          case key do
            {:fetch_text, url} ->
              if should_read_url_from_redis(url), do: read_redis_cache(url), else: nil

            _ ->
              nil
          end

        case from_redis do
          nil ->
            run_and_cache(key)

          value ->
            {:ok, value}
        end

      {:ok, :error} ->
        :error

      {:ok, value} ->
        {:ok, value}
    end
  end

  def html_document_at(url), do: read({:html_document, url})
  def json_at(url), do: read({:fetch_json, url})
  def text_at(url), do: read({:fetch_text, url})
  def content_length(url), do: read({:content_length, url})

  def clear_cache() do
    Cachex.clear(@cache_name)
  end
end
