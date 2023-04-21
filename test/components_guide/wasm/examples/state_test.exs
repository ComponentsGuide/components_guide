defmodule ComponentsGuide.Wasm.Examples.StateTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.State

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
      # assert Loader.get_current(a) == Loader.get_global(a, "idle")
      assert Loader.get_current(a) == 0
      Loader.begin(a)
      assert Loader.get_current(a) == 1
      Loader.success(a)
      assert Loader.get_current(a) == 2

      b = Loader.start()
      assert Loader.get_current(b) == 0

      Loader.success(b)
      assert Loader.get_current(b) == 0
      Loader.failure(b)
      assert Loader.get_current(b) == 0

      Loader.begin(b)
      assert Loader.get_current(b) == 1
      Loader.failure(b)
      assert Loader.get_current(b) == 3
    end
  end
end
