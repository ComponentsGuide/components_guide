defmodule ComponentsGuide.Fetch.Get do
  alias ComponentsGuide.Fetch.{Request, Response}

  @timeout 5000

  defmodule Timings do
    defstruct [:duration, :start]

    def start() do
      %__MODULE__{
        start: System.monotonic_time()
      }
    end

    def finish(timings = %__MODULE__{start: start}) do
      duration = System.monotonic_time() - start
      put_in(timings.duration, duration)
    end

    def start_with_telemetry(event_name, metadata \\ %{}) do
      t = start()

      :telemetry.execute(
        event_name,
        %{start: t.start},
        metadata
      )

      t
    end

    def finish_with_telemetry(t = %__MODULE__{}, event_name, metadata \\ %{}) do
      t = finish(t)

      :telemetry.execute(
        event_name,
        %{duration: t.duration},
        metadata
      )

      t
    end
  end

  def get_following_redirects!(url_string) when is_binary(url_string) do
    request = Request.new!(url_string)

    case load!(request) do
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

              _ ->
                {:error, {:invalid_url, location}}
            end
        end

      other ->
        other
    end
  end

  def load!(req = %Request{uri: %URI{host: host, port: 443}}) do
    t = Timings.start_with_telemetry([:fetch, :load!, :start], %{req: req})

    {:ok, conn} = Mint.HTTP.connect(:https, host, 443, mode: :passive, protocols: [:http1])
    {conn, response} = do_request(conn, req)
    Mint.HTTP.close(conn)

    t =
      Timings.finish_with_telemetry(t, [:fetch, :load!, :done], %{
        req: req
      })

    response = Response.add_timings(response, t)

    IO.puts(
      "Loaded #{req.url_string} in #{System.convert_time_unit(t.duration, :native, :millisecond)}ms. #{inspect(response.done?)}"
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

    {conn, results} =
      Enum.reduce(reqs, {conn, []}, fn
        %Request{uri: %URI{host: ^host, port: 443}} = req, {conn, results} ->
          t = Timings.start_with_telemetry([:fetch, :load_many!, :request, :start], %{req: req})

          {conn, response} = do_request(conn, req)

          t =
            Timings.finish_with_telemetry(t, [:fetch, :load_many!, :request, :done], %{
              req: req
            })

          response = Response.add_timings(response, t)

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
           uri: %URI{path: path},
           headers: headers,
           body: body,
           url_string: url_string
         }
       ) do
    result = Response.new(url_string)

    case Mint.HTTP.request(conn, method, path || "/", headers, body) do
      {:error, conn, reason} ->
        {conn, Response.add_error(result, reason)}

      {:ok, conn, request_ref} ->
        recv_all(result, conn, request_ref)
    end
  end
end