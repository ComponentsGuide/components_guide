defmodule ComponentsGuide.Wasm.Examples.StateTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.State

  describe "Counter" do
    alias State.Counter

    test "list exports" do
      assert Counter.exports() == [
               {:memory, "memory"},
               {:func, "get_current"},
               {:func, "increment"}
             ]
    end

    test "works" do
      # Like Agent.start(fun)
      instance = Counter.start()
      assert Counter.get_current(instance) == 0

      Counter.increment(instance)
      assert Counter.get_current(instance) == 1

      Counter.increment(instance)
      assert Counter.get_current(instance) == 2
    end
  end

  describe "Dialog" do
    alias State.Dialog

    test "works" do
      instance = Instance.run(Dialog)
      get_current = Instance.capture(instance, :get_current, 0)
      get_change_count = Instance.capture(instance, :get_change_count, 0)

      assert get_current.() == 0
      assert get_change_count.() == 0

      Dialog.open(instance)
      assert get_current.() == 1
      assert get_change_count.() == 1

      Dialog.close(instance)
      assert get_current.() == 0
      assert get_change_count.() == 2
    end

    test "wasm size" do
      wasm = Dialog.to_wasm()
      assert byte_size(wasm) == 204
    end
  end

  describe "Loader" do
    alias State.Loader

    test "exports" do
      assert Loader.exports() == [
               #  {{:global, "idle"}, %{type: :i32, mut: true}},
               #  {:global, %{name: "idle", type: :i32, mut: true}},
               {:global, "idle", :i32},
               {:global, "loading", :i32},
               {:global, "loaded", :i32},
               {:global, "failed", :i32},
               {:func, "get_current"},
               {:func, "begin"},
               {:func, "success"},
               {:func, "failure"},
               {:func, "get_change_count"}
             ]
    end

    test "works" do
      # Like Agent.start(fun)
      a = Loader.start()

      idle = Instance.get_global(a, "idle")
      loading = Instance.get_global(a, "loading")
      loaded = Instance.get_global(a, "loaded")
      failed = Instance.get_global(a, "failed")

      assert MapSet.new([idle, loading, loaded, failed]) |> MapSet.size() == 4

      assert Loader.get_current(a) == idle
      Loader.begin(a)
      assert Loader.get_current(a) == loading
      Loader.success(a)
      assert Loader.get_current(a) == loaded

      b = Loader.start()
      assert Loader.get_current(b) == idle

      Loader.success(b)
      assert Loader.get_current(b) == idle
      Loader.failure(b)
      assert Loader.get_current(b) == idle

      Loader.begin(b)
      assert Loader.get_current(b) == loading
      Loader.failure(b)
      assert Loader.get_current(b) == failed
    end
  end

  describe "Form" do
    alias State.Form

    test "works" do
      # Like Agent.start(fun)
      a = Form.start()

      initial = Instance.get_global(a, "initial")
      edited = Instance.get_global(a, "edited")
      submitting = Instance.get_global(a, "submitting")
      succeeded = Instance.get_global(a, "succeeded")
      failed = Instance.get_global(a, "failed")

      get_current = Instance.capture(a, :get_current, 0)
      get_edit_count = Instance.capture(a, :get_edit_count, 0)
      user_can_submit? = Instance.capture(a, :user_can_submit?, 0)

      assert MapSet.new([initial, edited, submitting, succeeded, failed]) |> MapSet.size() == 5

      assert get_current.() == initial
      assert get_edit_count.() == 0
      assert user_can_submit?.() == 1

      Form.user_did_edit(a)
      assert get_current.() == edited
      assert get_edit_count.() == 1
      assert user_can_submit?.() == 1

      Form.user_did_edit(a)
      assert get_current.() == edited
      assert get_edit_count.() == 2
      assert user_can_submit?.() == 1

      Form.user_did_submit(a)
      assert get_current.() == submitting
      assert get_edit_count.() == 2
      assert user_can_submit?.() == 0

      Form.user_did_submit(a)
      assert get_current.() == submitting
      assert get_edit_count.() == 2
      assert user_can_submit?.() == 0

      Form.destination_did_succeed(a)
      assert get_current.() == succeeded
      assert get_edit_count.() == 2
      assert user_can_submit?.() == 1

      b = Form.start()
      get_current = Instance.capture(b, :get_current, 0)
      user_can_submit? = Instance.capture(a, :user_can_submit?, 0)

      Form.user_did_edit(b)
      Form.user_did_submit(b)
      Form.destination_did_fail(b)
      assert get_current.() == failed
      assert user_can_submit?.() == 1
    end
  end

  describe "LamportClock" do
    alias State.LamportClock

    # test "validate definition", do: LamportClock.validate_definition!()

    test "works" do
      a = LamportClock.start()
      b = LamportClock.start()

      assert LamportClock.received(a, 7) == 8

      LamportClock.send(a, b)

      assert LamportClock.read(a) == 9
      assert LamportClock.read(b) == 10
    end
  end

  describe "LiveAPIConnection" do
    alias State.LiveAPIConnection

    defmodule Manager do
      use GenServer

      defmodule State do
        @keys [:parent, :ping_ref, :tref]
        defstruct @keys

        def new(parent), do: %__MODULE__{parent: parent}
      end

      def start_link(opts \\ nil) do
        state = State.new(self())
        GenServer.start_link(__MODULE__, state)
      end

      @impl GenServer
      def init(state) do
        {:ok, state}
      end

      defp do_ping(state) do
        ping_ref = Process.send_after(self(), :pong, 20)
        %State{state | ping_ref: ping_ref}
      end

      @impl GenServer
      def handle_call(:request_ping, _from, state) do
        state = do_ping(state)
        {:reply, :ok, state}
      end

      @impl GenServer
      def handle_call({:timer_ms, msg, duration_ms}, from, state) when is_number(duration_ms) do
        # tref = :timer.send_after(duration_ms, self(), {:timer_finished, from, msg, duration_ms})
        tref = Process.send_after(self(), {:timer_finished, from, msg, duration_ms}, duration_ms)
        {:reply, :ok, %{state | tref: tref}}
      end

      @impl GenServer
      def handle_info(:pong, state) do
        send(state.parent, :pong)
        {:noreply, state}
      end

      @impl GenServer
      def handle_info({:timer_finished, from, :heartbeat, _duration}, state) do
        state = do_ping(state)
        {:noreply, state}
      end

      @impl GenServer
      def handle_info({:timer_finished, from, msg, _duration}, state) do
        IO.puts("timer finished #{msg}")
        {:noreply, state}
      end

      def heartbeat_after(pid, 0), do: nil

      def heartbeat_after(pid, duration_ms) do
        GenServer.call(pid, {:timer_ms, :heartbeat, duration_ms})
        :ok
      end

      def heartbeat_now(pid, if: 0), do: nil
      def heartbeat_now(pid, if: _), do: GenServer.call(pid, :request_ping)
    end

    test "works" do
      IO.puts(LiveAPIConnection.to_wat())
      instance = Instance.run(LiveAPIConnection)

      {:ok, manager} = Manager.start_link()

      initial = Instance.get_global(instance, :initial)
      connecting = Instance.get_global(instance, :connecting)
      connected = Instance.get_global(instance, :connected)
      reconnecting = Instance.get_global(instance, :reconnecting)
      disconnected = Instance.get_global(instance, :disconnected)

      get_current = Instance.capture(instance, :get_current, 0)
      get_path = Instance.capture(instance, String, :get_path, 0)
      get_debug_path = Instance.capture(instance, String, :get_debug_path, 0)
      info_success_count = Instance.capture(instance, :info_success_count, 0)
      effect_heartbeat? = Instance.capture(instance, :effect_heartbeat?, 0)
      timer_ms_heartbeat = Instance.capture(instance, :timer_ms_heartbeat, 0)
      timeout_ms_pong = Instance.capture(instance, :timeout_ms_pong, 0)

      assert get_current.() == initial
      assert get_path.() == "/initial"
      assert info_success_count.() == 0
      assert effect_heartbeat?.() == 0
      assert timer_ms_heartbeat.() == 0

      Instance.call(instance, :connect)
      assert get_current.() == connecting
      assert get_path.() == "/connecting"
      assert info_success_count.() == 0
      assert effect_heartbeat?.() == 0
      assert timer_ms_heartbeat.() == 0

      Instance.call(instance, :auth_succeeded)
      assert get_current.() == connecting
      assert get_path.() == "/connecting"
      assert info_success_count.() == 0
      assert effect_heartbeat?.() == 0
      assert timer_ms_heartbeat.() == 0

      Instance.call(instance, :connecting_succeeded)
      assert get_current.() == connected
      assert get_path.() == "/connected"
      assert info_success_count.() == 1
      assert effect_heartbeat?.() == 0
      assert timer_ms_heartbeat.() == 30_000
      Manager.heartbeat_after(manager, div(timer_ms_heartbeat.(), 1000))

      assert_receive :pong
      Instance.call(instance, :pong)
      assert get_current.() == connected
      assert get_path.() == "/connected"

      Instance.call(instance, :window_did_focus)
      assert get_current.() == connected
      assert get_path.() == "/connected"
      assert info_success_count.() == 1
      assert effect_heartbeat?.() == 1
      assert timer_ms_heartbeat.() == 0
      assert timeout_ms_pong.() == 2_000
      Manager.heartbeat_now(manager, if: effect_heartbeat?.())

      # assert_receive :pong, timeout_ms_pong.()
      # Instance.call(instance, :pong)
      # assert get_current.() == connected
      # assert get_path.() == "/connected"

      assert get_debug_path.() == "/ok_awaiting_pong"
      Instance.call(instance, :pong_timedout)
      assert get_debug_path.() == "/connecting_busy"
      assert get_current.() == reconnecting
      assert get_path.() == "/reconnecting"
    end
  end

  describe "FlightBooking" do
    alias State.FlightBooking

    test "works" do
      # IO.puts(FlightBooking.to_wat())
      instance = FlightBooking.start()

      initial? = Instance.get_global(instance, :initial?)
      destination? = Instance.get_global(instance, :destination?)
      dates? = Instance.get_global(instance, :dates?)
      flights? = Instance.get_global(instance, :flights?)
      seats? = Instance.get_global(instance, :seats?)

      get_current = Instance.capture(instance, :get_current, 0)
      get_path = Instance.capture(instance, String, :get_path, 0)
      # get_path = Instance.capture(instance, :get_path, 0)
      next = Instance.capture(instance, :next, 0)

      assert get_current.() == initial?
      # assert Instance.call_reading_string(instance, :get_path) == ""
      assert get_path.() == "/book"

      next.()
      assert get_current.() == destination?
      assert get_path.() == "/destination"

      next.()
      assert get_current.() == dates?
      assert get_path.() == "/dates"

      next.()
      assert get_current.() == flights?
      assert get_path.() == "/flights"

      next.()
      assert get_current.() == seats?
      assert get_path.() == "/seats"
    end
  end
end
