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

  defp redis_config() do
    upstash_config = Application.fetch_env!(:components_guide, :upstash)

    %{
      url: upstash_config[:redis_rest_url],
      token: upstash_config[:redis_rest_token]
    }
  end

  defp read_redis_cache(key) do
    {duration_microseconds, result} =
      :timer.tc(fn ->
        case Redix.command(:upstash_redix, ["GET", key]) do
          {:ok, value} -> value
          _ -> nil
        end
      end)

    IO.puts("read from redis #{key} in #{duration_microseconds} microseconds")
    IO.inspect(result)
    result
  end

  defp write_redis_cache(key, value) do
    result = Redix.command(:upstash_redix, ["SET", key, value])
    IO.puts("REdis write")
    IO.inspect(result)
  end

  defp read_rest_redis_cache(key) do
    %{url: url, token: token} = redis_config()
    urlsafe_key = Base.url_encode64(key)

    request =
      Fetch.Request.new!("#{url}/get/#{urlsafe_key}",
        headers: [{"Authorization", "Bearer #{token}"}]
      )

    response = Fetch.load!(request)

    # term = :erlang.binary_to_term(response.body, [:safe])
    # term

    IO.inspect(response)

    with body when not is_nil(response.body) <- response.body,
         {:ok, %{"result" => value}} <- Jason.decode(body) do
      IO.inspect(value)
      value
    else
      _ ->
        nil
    end
  end

  defp write_rest_redis_cache(key, value) do
    urlsafe_key = Base.url_encode64(key)
    body = ["SET", urlsafe_key, value] |> Jason.encode_to_iodata!()
    # body = value |> Jason.encode_to_iodata!(value)
    # body = value
    # body = :erlang.term_to_iovec(value)

    %{url: url, token: token} = redis_config()

    request =
      Fetch.Request.new!(url,
        method: "POST",
        headers: [
          {"Authorization", "Bearer #{token}"},
          {"Content-Type", "application/json"}
        ],
        body: body
      )

    response = Fetch.load!(request)
    IO.inspect(response)
  end

  defp run({:fetch_text, url}) do
    IO.puts("fetching URL #{url}")

    response = Fetch.get!(url)

    case response.status do
      200 ->
        {:ok, response.body}

      status ->
        {:error, {:http_status, status}}
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

  defp run({:fetch_json, url}) do
    with {:ok, text} when not is_nil(text) <- read({:fetch_text, url}),
         {:ok, data} <- Jason.decode(text) do
      {:ok, data}
    else
      _ -> :error
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
          # write_redis_cache(url, value)
          write_rest_redis_cache(url, value)

        _ ->
          nil
      end

      {:ok, value}
    else
      _ ->
        write_cache(key, :error)
        :error
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
              if should_read_url_from_redis(url), do: read_rest_redis_cache(url), else: nil

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
  def content_length(url), do: read({:content_length, url})

  def clear_cache() do
    Cachex.clear(@cache_name)
  end
end
