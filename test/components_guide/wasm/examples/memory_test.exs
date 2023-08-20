defmodule ComponentsGuide.Wasm.Examples.MemoryTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.{Instance, Wasm}
  alias ComponentsGuide.Wasm.Examples.Memory

  describe "LinkedLists" do
    alias Memory.LinkedLists

    test "wasm size" do
      wasm = Wasm.to_wasm(LinkedLists)
      assert byte_size(wasm) == 326
    end

    test "multiple allocations" do
      inst = LinkedLists.start()
      # alloc = Instance.capture(inst, :_test_alloc, 1)
      cons = Instance.capture(inst, :cons, 2)
      count = Instance.capture(inst, :list_count, 1)
      sum = Instance.capture(inst, :list32_sum, 1)

      enum = fn node ->
        Stream.unfold(node, fn node ->
          case Instance.call(inst, :hd, node) do
            0x0 -> nil
            value -> {value, Instance.call(inst, :tl, node)}
          end
        end)
      end

      # i1 = alloc.(0x4)
      # i2 = alloc.(0x4)
      # i3 = alloc.(0x4)
      l1 = cons.(3, 0x0)
      l2 = cons.(4, l1)
      l3 = cons.(5, l2)
      l4 = cons.(6, l3)

      # Instance.write_i32(inst, i1, 0xdeadbeef)
      # Instance.write_i32(inst, i1, 3)
      # Instance.write_i32(inst, i2, 4)
      # Instance.write_i32(inst, i3, 5)

      Instance.log_memory(inst, 0x10000, 32)

      assert Enum.to_list(enum.(l4)) == [6, 5, 4, 3]
      assert Enum.to_list(enum.(l3)) == [5, 4, 3]
      assert Enum.to_list(enum.(l2)) == [4, 3]
      assert Enum.to_list(enum.(l1)) == [3]

      assert count.(0x0) == 0
      assert count.(l1) == 1
      assert count.(l2) == 2
      assert count.(l3) == 3
      assert count.(l4) == 4

      assert sum.(0x0) == 0
      assert sum.(l1) == 3
      assert sum.(l2) == 7
      assert sum.(l3) == 12
      assert sum.(l4) == 18

      Instance.call(inst, :reverse_in_place, l4)
      Instance.log_memory(inst, 0x10000, 32)
      assert Enum.to_list(enum.(l1)) == [3, 4, 5, 6]
      # TODO: is this the right behavior?
      assert Enum.to_list(enum.(l2)) == [4, 5, 6]
      assert Enum.to_list(enum.(l3)) == [5, 6]
      assert Enum.to_list(enum.(l4)) == [6]
    end
  end
end
