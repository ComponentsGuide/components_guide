defmodule ComponentsGuide.Wasm.Examples.StateTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.State

  describe "Counter" do
    alias State.Counter

    test "list exports" do
      assert Counter.exports() == [
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
               {:func, "failure"}
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
      can_submit? = Instance.capture(a, :can_submit, 0)

      assert MapSet.new([initial, edited, submitting, succeeded, failed]) |> MapSet.size() == 5

      assert get_current.() == initial
      assert get_edit_count.() == 0
      assert can_submit?.() == 1

      Form.did_edit(a)
      assert get_current.() == edited
      assert get_edit_count.() == 1
      assert can_submit?.() == 1

      Form.did_edit(a)
      assert get_current.() == edited
      assert get_edit_count.() == 2
      assert can_submit?.() == 1

      Form.did_submit(a)
      assert get_current.() == submitting
      assert get_edit_count.() == 2
      assert can_submit?.() == 0

      Form.did_submit(a)
      assert get_current.() == submitting
      assert get_edit_count.() == 2
      assert can_submit?.() == 0

      Form.did_succeed(a)
      assert get_current.() == succeeded
      assert get_edit_count.() == 2
      assert can_submit?.() == 1

      b = Form.start()
      get_current = Instance.capture(b, :get_current, 0)
      can_submit? = Instance.capture(a, :can_submit, 0)

      Form.did_edit(b)
      Form.did_submit(b)
      Form.did_fail(b)
      assert get_current.() == failed
      assert can_submit?.() == 1
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
end
