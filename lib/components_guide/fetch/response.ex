defmodule ComponentsGuide.Fetch.Response do
  alias ComponentsGuide.Fetch.Timings

  defstruct done?: false,
            url: nil,
            status: nil,
            headers: [],
            body: "",
            error: nil,
            timings: %Timings{}

  def new(url_string, timings = %Timings{}) do
    %__MODULE__{url: url_string, done?: false, timings: timings}
  end

  def failed(url_string, error) do
    new(url_string, nil) |> add_error(error)
  end

  def add_responses(receiver = %__MODULE__{}, responses, ref) do
    Enum.reduce(responses, receiver, fn
      {:status, ^ref, code}, acc ->
        IO.puts("status #{code}")

        acc
        |> Map.update!(:timings, &Timings.did_receive_status/1)
        |> Map.put(:status, code)

      {:headers, ^ref, headers}, acc ->
        IO.puts("headers")

        acc
        |> Map.update!(:timings, &Timings.did_receive_headers/1)
        |> Map.update(:headers, headers, &(&1 ++ headers))

      {:data, ^ref, data}, acc ->
        IO.puts("data")
        Map.update(acc, :body, data, &(&1 <> data))

      {:done, ^ref}, acc ->
        IO.puts("done")
        Map.put(acc, :done?, true)
    end)
  end

  def finish_timings(receiver = %__MODULE__{}, event_name, metadata \\ %{}) do
    update_in(receiver.timings, &Timings.finish_with_telemetry(&1, event_name, metadata))
  end

  def add_error(receiver = %__MODULE__{}, error) do
    put_in(receiver.error, error)
  end

  def find_header(receiver = %__MODULE__{}, header_name) when is_binary(header_name) do
    header_name = String.downcase(header_name)

    Enum.find_value(receiver.headers, fn {name, value} ->
      case String.downcase(name) do
        ^header_name -> value
        _ -> nil
      end
    end)
  end
end
