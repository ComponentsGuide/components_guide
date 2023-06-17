defmodule ComponentsGuide.Wasm.Examples.MemoryTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Memory

  describe "Copying" do
    alias Memory.Copying

    setup do: %{inst: Instance.run(Copying)}

    test "memcpy", %{inst: inst} do
      memcpy = Instance.capture(inst, :memcpy, 3)

      p1 = 0xE00
      p2 = 0xF00
      Instance.write_i32(inst, p1, 0x12345678)
      memcpy.(p2, p1, 4)
      assert Instance.read_memory(inst, p1, 4) == <<0x78, 0x56, 0x34, 0x12>>
      assert Instance.read_memory(inst, p2, 4) == <<0x78, 0x56, 0x34, 0x12>>
    end
  end

  describe "BumpAllocator" do
    alias Memory.BumpAllocator

    test "compiles" do
      Instance.run(BumpAllocator)
    end

    test "single allocation" do
      assert Wasm.call(BumpAllocator, :alloc, 16) == 64 * 1024
    end

    test "multiple allocations" do
      inst = Instance.run(BumpAllocator)
      alloc = Instance.capture(inst, :alloc, 1)
      free_all = Instance.capture(inst, :free_all, 0)

      assert alloc.(0x10) == 0x10000
      assert alloc.(0x10) == 0x10010
      assert alloc.(0x10) == 0x10020
      free_all.()
      assert alloc.(0x10) == 0x10000
      assert alloc.(0x10) == 0x10010
      assert alloc.(0x10) == 0x10020
    end
  end

  describe "LinkedLists" do
    alias Memory.LinkedLists

    # test "single allocation" do
    #   IO.puts(LinkedLists.to_wat())
    #   assert Wasm.call(LinkedLists, :_test_cons, 0x0, 0x0) == 0x10000
    # end

    test "multiple allocations" do
      inst = LinkedLists.start()
      # alloc = Instance.capture(inst, :_test_alloc, 1)
      cons = Instance.capture(inst, :_test_cons, 2)
      count = Instance.capture(inst, :_test_list_count, 1)
      sum = Instance.capture(inst, :_test_list32_sum, 1)

      enum = fn node ->
        Stream.unfold(node, fn node ->
          case Instance.call(inst, :_test_hd, node) do
            0x0 -> nil
            value -> {value, Instance.call(inst, :_test_tl, node)}
          end
        end)
      end

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

      assert Enum.to_list(enum.(l3)) == [5, 4, 3]

      assert count.(0x0) == 0
      assert count.(l1) == 1
      assert count.(l2) == 2
      assert count.(l3) == 3

      assert sum.(0x0) == 0
      assert sum.(l1) == 3
      assert sum.(l2) == 7
      assert sum.(l3) == 12

      Instance.call(inst, :_test_reverse, l3)
      Instance.log_memory(inst, 0x10000, 32)
      assert Enum.to_list(enum.(l1)) == [3, 4, 5]
    end
  end
end
