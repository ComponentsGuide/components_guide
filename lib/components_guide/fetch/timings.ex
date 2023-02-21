defmodule ComponentsGuide.Fetch.Timings do
  defstruct [:start, :connected, :received_status, :received_headers, :duration]

  def start() do
    %__MODULE__{
      start: System.monotonic_time()
    }
  end

  def did_connect(timings = %__MODULE__{start: start}) do
    duration = System.monotonic_time() - start
    put_in(timings.connected, duration)
  end

  def did_receive_status(timings = %__MODULE__{start: start}) do
    duration = System.monotonic_time() - start
    put_in(timings.received_status, duration)
  end

  def did_receive_headers(timings = %__MODULE__{start: start}) do
    duration = System.monotonic_time() - start
    put_in(timings.received_headers, duration)
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
