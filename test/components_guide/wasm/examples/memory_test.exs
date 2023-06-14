defmodule ComponentsGuide.Wasm.Examples.MemoryTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Memory

  describe "BumpAllocator" do
    alias Memory.BumpAllocator

    test "compiles" do
      try do
        BumpAllocator.start()
      rescue
        RuntimeError ->
          IO.puts(BumpAllocator.to_wat())
      end
    end

    test "single allocation" do
      assert Wasm.call(BumpAllocator, :alloc, 16) == 64 * 1024
    end

    test "multiple allocations" do
      inst = BumpAllocator.start()
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

    test "memcpy" do
      inst = BumpAllocator.start()
      alloc = Instance.capture(inst, :alloc, 1)
      memcpy = Instance.capture(inst, :memcpy, 1)
    end
  end

  describe "MemEql" do
    alias Memory.MemEql

    test "mem_eql_8" do
      inst = MemEql.start()
      mem_eql_8 = Instance.capture(inst, :_mem_eql_8, 2)

      Instance.write_string_nul_terminated(inst, 0x00100, "hello")
      Instance.write_string_nul_terminated(inst, 0x00200, "world")
      assert mem_eql_8.(0x00100, 0x00200) == 0

      Instance.write_string_nul_terminated(inst, 0x00100, "hello")
      Instance.write_string_nul_terminated(inst, 0x00200, "hello")
      assert mem_eql_8.(0x00100, 0x00200) == 1

      Instance.write_string_nul_terminated(inst, 0x00100, "hellp")
      Instance.write_string_nul_terminated(inst, 0x00200, "hello")
      assert mem_eql_8.(0x00100, 0x00200) == 0

      Instance.write_string_nul_terminated(inst, 0x00100, "hi\0\0\0")
      Instance.write_string_nul_terminated(inst, 0x00200, "hip\0\0")
      assert mem_eql_8.(0x00100, 0x00200) == 0

      Instance.write_string_nul_terminated(inst, 0x00100, "hip\0\0")
      Instance.write_string_nul_terminated(inst, 0x00200, "hi\0\0\0")
      assert mem_eql_8.(0x00100, 0x00200) == 0

      Instance.write_string_nul_terminated(inst, 0x00100, "\0\0\0\0\0")
      Instance.write_string_nul_terminated(inst, 0x00200, "\0\0\0\0\0")
      assert mem_eql_8.(0x00100, 0x00200) == 1

      Instance.write_string_nul_terminated(inst, 0x00100, "h\0\0\0\0")
      Instance.write_string_nul_terminated(inst, 0x00200, "\0\0\0\0\0")
      assert mem_eql_8.(0x00100, 0x00200) == 0

      Instance.write_string_nul_terminated(inst, 0x00100, "\0\0\0\0\0")
      Instance.write_string_nul_terminated(inst, 0x00200, "h\0\0\0\0")
      assert mem_eql_8.(0x00100, 0x00200) == 0
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

      enum = fn (node) ->
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
