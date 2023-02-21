defmodule ComponentsGuide.Fetch do
  alias ComponentsGuide.Fetch.{Request, Response, Timings}

  @timeout 5000

  @doc ~S"""
  Fetches the given URL, following redirects (if any).
  """
  def get!(url_string) when is_binary(url_string) do
    get_following_redirects!(url_string)
  end

  def get_following_redirects!(url_string) when is_binary(url_string) do
    response =
      case Request.new(url_string) do
        {:ok, request} ->
          load!(request)

        {:error, reason} ->
          Response.failed(url_string, reason)
      end

    case response do
      %Response{status: status, headers: headers} = resp when status >= 300 and status < 400 ->
        case Enum.find(headers, fn {key, _} -> key == "location" end) do
          # No redirect!
          nil ->
            resp

          {_, location} ->
            IO.puts("Following #{status} redirect to #{location}")

            case Request.new(location) do
              {:ok, request} ->
                # TODO: use existing conn if host is the same.
                load!(request)

              {:error, reason} ->
                Response.failed(url_string, reason)
            end
        end

      other ->
        other
    end
  end

  def load!(req = %Request{uri: %URI{host: host, port: 443}}, protocols \\ [:http1, :http2]) do
    t = Timings.start_with_telemetry([:fetch, :load!, :start], %{req: req})

    {:ok, conn} = Mint.HTTP.connect(:https, host, 443, mode: :passive, protocols: protocols)
    t = t |> Timings.did_connect()
    {conn, response} = do_request(conn, req, t)
    Mint.HTTP.close(conn)

    response = Response.finish_timings(response, [:fetch, :load!, :done], %{req: req})

    IO.puts(
      "Loaded #{req.url_string} in #{System.convert_time_unit(response.timings.duration, :native, :millisecond)}ms. #{inspect(response.done?)}"
    )

    response
  end

  def load_many_example(n \\ 2) do
    load_many!(
      "components.guide",
      Enum.map(0..n, fn _ -> Request.new!("https://components.guide/") end)
    )
  end

  def load_many!(host, reqs) when is_binary(host) and is_list(reqs) do
    t = Timings.start_with_telemetry([:fetch, :load_many!, :start], %{host: host})

    {:ok, conn} = Mint.HTTP.connect(:https, host, 443, mode: :passive, protocols: [:http1])
    t = t |> Timings.did_connect()

    {conn, results} =
      Enum.reduce(reqs, {conn, []}, fn
        %Request{uri: %URI{host: ^host, port: 443}} = req, {conn, results} ->
          t = Timings.start_with_telemetry([:fetch, :load_many!, :request, :start], %{req: req})

          {conn, response} = do_request(conn, req, t)

          response = Response.finish_timings(response, [:fetch, :load_many!, :request, :done], %{req: req})

          {conn, [response | results]}
      end)

    Mint.HTTP.close(conn)
    results = Enum.reverse(results)

    Timings.finish_with_telemetry(t, [:fetch, :load_many!, :done], %{host: host})
    results
  end

  defp recv_all(result = %Response{done?: true}, conn, _request_ref), do: {conn, result}

  defp recv_all(result, conn, request_ref) do
    case Mint.HTTP.recv(conn, 0, @timeout) do
      {:ok, conn, responses} ->
        Response.add_responses(result, responses, request_ref)
        |> recv_all(conn, request_ref)

      {:error, conn, error, _responses} ->
        {conn, Response.add_error(result, error)}
    end
  end

  defp do_request(
         conn,
         %Request{
           method: method,
           uri: uri,
           headers: headers,
           body: body,
           url_string: url_string
         },
         timings = %Timings{}
       ) do
    result = Response.new(url_string, timings)
    path_and_query = %URI{path: uri.path || "/", query: uri.query} |> URI.to_string()

    case Mint.HTTP.request(conn, method, path_and_query, headers, body) do
      {:error, conn, reason} ->
        {conn, Response.add_error(result, reason)}

      {:ok, conn, request_ref} ->
        recv_all(result, conn, request_ref)
    end
  end
end
