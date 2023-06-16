defmodule ComponentsGuide.Wasm.Examples.Memory do
  alias ComponentsGuide.Wasm

  defmodule BumpAllocator do
    use Wasm

    @page_size 64 * 1024
    @bump_start 1 * @page_size

    # defmacro globals() do
    #   unquote(Macro.escape([bump_offset: i32(@bump_start)]))
    # end

    defmacro __using__(_opts) do
      quote do
        @wasm_memory 2

        import unquote(__MODULE__)
      end
    end

    defmacro bump_offset(), do: Macro.escape(@bump_start)

    defwasm exported_memory: 2,
            globals: [
              bump_offset: i32(@bump_start)
            ] do
      funcp bump_alloc(size(I32)), I32, address: I32 do
        # TODO: check if we have allocated too much
        # and if so, either err or increase the available memory.
        address = bump_offset
        bump_offset = I32.add(bump_offset, size)
        address
      end

      funcp bump_free_all() do
        bump_offset = @bump_start
      end

      funcp bump_memcpy(dest(I32), src(I32), byte_count(I32)),
            nil,
            i: I32 do
        loop EachByte do
          memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned

          if I32.lt_u(i, byte_count) do
            i = I32.add(i, 1)
            EachByte.continue()
          end
        end

        #         loop :each_byte do
        #           memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
        # 
        #           if I32.lt_u(i, byte_count) do
        #             i = I32.add(i, 1)
        #             :each_byte
        #           end
        #         end

        #         loop :i do
        #           memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
        # 
        #           if I32.lt_u(i, byte_count) do
        #             i = I32.add(i, 1)
        #             {:br, :i}
        #           end
        #         end

        #       loop i, 0..byte_count do
        #         memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
        #       end

        #       loop i, I32.lt_u(byte_count), I32.add(1) do
        #         memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
        #       end

        #       loop i, I32.add do
        #         i ->
        #           memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
        # 
        #           I32.lt_u(i, byte_count)
        #       end
      end

      func alloc(size(I32)), result: I32 do
        call(:bump_alloc, size)
      end

      func free_all() do
        call(:bump_free_all)
      end

      func memcpy(dest(I32), src(I32), byte_count(I32)) do
        call(:bump_memcpy, dest, src, byte_count)
      end
    end

    def alloc(byte_count) do
      call(:bump_alloc, byte_count)
    end

    def memcpy(dest, src, byte_count) do
      call(:bump_memcpy, dest, src, byte_count)
    end

    # def memcpy(dest, {:const_string, string}) do
    #   call(:bump_memcpy, dest, src, byte_count(string))
    # end
  end

  defmodule MemEql do
    use Wasm

    @wasm_memory 1

    defwasm do
      funcp mem_eql_8(address_a(I32), address_b(I32)),
        result: I32,
        locals: [i: I32, byte_a: I32, byte_b: I32] do
        loop EachByte, result: I32 do
          byte_a = memory32_8![I32.add(address_a, i)].unsigned
          byte_b = memory32_8![I32.add(address_b, i)].unsigned

          if I32.eqz(byte_a) do
            return(I32.eqz(byte_b))
          end

          if I32.eq(byte_a, byte_b) do
            i = I32.add(i, 1)
            EachByte.continue()
            # return(0x1)
          end

          return(0x0)
        end
      end

      raw_wat(~S[(export "_mem_eql_8" (func $mem_eql_8))])
    end
  end

  defmodule StringHelpers do
    use Wasm
    use BumpAllocator

    defwasm do
      func strlen(string_ptr(I32)), result: I32, locals: [count: I32] do
        # while (string_ptr[count] != 0) {
        #   count++;
        # }

        # loop EachChar, while: memory32_8![count] do
        loop EachChar do
          if memory32_8![I32.add(string_ptr, count)].unsigned do
            count = I32.add(count, 1)
            EachChar.continue()
          end
        end

        count
      end
    end

    def strlen(string_ptr), do: call(:strlen, string_ptr)
  end

  defmodule LinkedLists do
    use Wasm

    @page_size 64 * 1024
    @bump_start 1 * @page_size

    defwasm imports: [
              env: [buffer: memory(1)]
              # log: [
              #   int32: func(name: :log32, params: I32, result: I32)
              # ]
            ],
            globals: [
              bump_offset: i32(@bump_start)
            ] do
      cpfuncp(bump_alloc, from: BumpAllocator, result: I32)

      funcp cons(hd(I32), tl(I32)), result: I32, locals: [ptr: I32] do
        ptr = call(:bump_alloc, 8)
        memory32![ptr] = hd
        memory32![I32.add(ptr, 4)] = tl
        ptr
      end

      funcp hd(ptr(I32)), result: I32 do
        I32.if_eqz(ptr, do: 0x0, else: memory32![ptr])
        # I32.eqz(ptr) |> I32.if_else(do: 0x0, else: memory32![ptr])
      end

      funcp tl(ptr(I32)), result: I32 do
        I32.if_eqz(ptr, do: 0x0, else: memory32![I32.add(ptr, 4)])
      end

      funcp reverse(node(I32)), result: I32, locals: [prev: I32, current: I32, next: I32] do
        current = node

        loop Iterate, result: I32 do
          if I32.eqz(current), do: return(prev)

          next = memory32![I32.add(current, 4)]
          memory32![I32.add(current, 4)] = prev
          prev = current
          current = next
          Iterate.continue()
        end
      end

      funcp list_count(ptr(I32)), result: I32, locals: [count: I32] do
        loop Iterate, result: I32 do
          if I32.eqz(ptr), do: return(count)
          # if I32.eqz(ptr), return: count
          # return(count, if: I32.eqz(ptr))
          # guard ptr, else_return: count

          ptr = call(:tl, ptr)
          count = I32.add(count, 1)
          Iterate.continue()
        end
      end

      funcp list32_sum(ptr(I32)), result: I32, locals: [sum: I32] do
        loop Iterate, result: I32 do
          if I32.eqz(ptr), do: return(sum)

          sum = I32.add(sum, call(:hd, ptr))
          ptr = call(:tl, ptr)

          Iterate.continue()
        end
      end

      # export_test_func :bump_alloc
      raw_wat(~S[(export "_test_alloc" (func $bump_alloc))])
      raw_wat(~S[(export "_test_cons" (func $cons))])
      raw_wat(~S[(export "_test_hd" (func $hd))])
      raw_wat(~S[(export "_test_tl" (func $tl))])
      raw_wat(~S[(export "_test_reverse" (func $reverse))])
      raw_wat(~S[(export "_test_list_count" (func $list_count))])
      raw_wat(~S[(export "_test_list32_sum" (func $list32_sum))])
    end

    def start() do
      imports = [
        {:log, :int32,
         fn value ->
           IO.inspect(value, label: "wasm log int32")
           0
         end}
      ]

      ComponentsGuide.Wasm.run_instance(__MODULE__, imports)
    end
  end
end
