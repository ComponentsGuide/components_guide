defmodule ComponentsGuide.Fetch.Response do
  defstruct done?: false, url: nil, status: nil, headers: [], body: "", error: nil, timings: nil

  def new(url_string) do
    %__MODULE__{url: url_string, done?: false}
  end

  def failed(url_string, error) do
    new(url_string) |> add_error(error)
  end

  def add_responses(receiver = %__MODULE__{}, responses, ref) do
    Enum.reduce(responses, receiver, fn
      {:status, ^ref, code}, acc ->
        IO.puts("status #{code}")
        Map.put(acc, :status, code)

      {:headers, ^ref, headers}, acc ->
        IO.puts("headers")
        Map.update(acc, :headers, headers, &(&1 ++ headers))

      {:data, ^ref, data}, acc ->
        IO.puts("data")
        Map.update(acc, :body, data, &(&1 <> data))

      {:done, ^ref}, acc ->
        IO.puts("done")
        Map.put(acc, :done?, true)
    end)
  end

  def add_timings(receiver = %__MODULE__{}, timings) do
    put_in(receiver.timings, timings)
  end

  def add_error(receiver = %__MODULE__{}, error) do
    put_in(receiver.error, error)
  end
end
