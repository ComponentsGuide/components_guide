defmodule ComponentsGuide.Wasm.Examples.MemoryTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Memory

  describe "BumpAllocator" do
    alias Memory.BumpAllocator

    test "single allocation" do
      assert Wasm.call(BumpAllocator, :alloc, 16) == 64 * 1024
    end

    test "multiple allocations" do
      inst = BumpAllocator.start()
      assert Instance.call(inst, :alloc, 0x10) == 0x10000
      assert Instance.call(inst, :alloc, 0x10) == 0x10010
      assert Instance.call(inst, :alloc, 0x10) == 0x10020
      Instance.call(inst, :free_all)
      assert Instance.call(inst, :alloc, 0x10) == 0x10000
      assert Instance.call(inst, :alloc, 0x10) == 0x10010
      assert Instance.call(inst, :alloc, 0x10) == 0x10020
    end
  end

  describe "LinkedLists" do
    alias Memory.LinkedLists

    # test "single allocation" do
    #   IO.puts(LinkedLists.to_wat())
    #   assert Wasm.call(LinkedLists, :_test_cons, 0x0, 0x0) == 0x10000
    # end

    test "multiple allocations" do
      inst = LinkedLists.start(nil)
      alloc = Instance.capture(inst, :_test_alloc, 1)
      cons = Instance.capture(inst, :_test_cons, 2)
      count = Instance.capture(inst, :_test_list_count, 1)
      sum = Instance.capture(inst, :_test_list32_sum, 1)

      # i1 = alloc.(0x4)
      # i2 = alloc.(0x4)
      # i3 = alloc.(0x4)
      l1 = cons.(3, 0x0)
      l2 = cons.(4, l1)
      l3 = cons.(5, l2)

      # Instance.write_i32(inst, i1, 0xdeadbeef)
      # Instance.write_i32(inst, i1, 3)
      # Instance.write_i32(inst, i2, 4)
      # Instance.write_i32(inst, i3, 5)

      Instance.log_memory(inst, 0x10000, 32)

      assert count.(0x0) == 0
      assert count.(l1) == 1
      assert count.(l2) == 2
      assert count.(l3) == 3
      assert sum.(0x0) == 0
      assert sum.(l1) == 3
      assert sum.(l2) == 7
      assert sum.(l3) == 12
    end
  end
end
