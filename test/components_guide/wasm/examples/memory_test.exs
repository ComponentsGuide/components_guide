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
      IO.puts(LinkedLists.to_wat())
      inst = LinkedLists.start(nil)
      alloc = LinkedLists.capture(inst, :_test_alloc, 1)
      cons = LinkedLists.capture(inst, :_test_cons, 2)
      count = LinkedLists.capture(inst, :_test_count, 1)

      i1 = alloc.(0x4)
      i2 = alloc.(0x4)
      i3 = alloc.(0x4)
      l1 = cons.(i1, 0x0)
      l2 = cons.(i2, l1)
      l3 = cons.(i3, l2)

      Instance.write_i32(inst, i1, 0xdeadbeef)

      Instance.log_memory(inst, 0x10000, 32)
      Instance.log_memory(inst, 0x10005, 32)

      assert i1 == 0x10000
      assert i2 == 0x10004
      assert i3 == 0x10008
      assert l1 == 0x1000c
      assert l2 == 0x10014
      assert l3 == 0x1001c
      assert count.(l1) == 1
      assert count.(l2) == 2
      assert count.(l3) == 3
    end
  end
end
