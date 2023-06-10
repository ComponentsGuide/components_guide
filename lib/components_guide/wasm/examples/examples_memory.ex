defmodule ComponentsGuide.Wasm.Examples.Memory do
  alias ComponentsGuide.Wasm

  defmodule BumpAllocator do
    use Wasm

    @page_size 64 * 1024
    @bump_start 1 * @page_size

    # defmacro globals() do
    #   unquote(Macro.escape([bump_offset: i32(@bump_start)]))
    # end

    defwasm globals: [
              bump_offset: i32(@bump_start)
            ] do
      funcp bump_alloc(size(I32)), result: I32, locals: [address: I32] do
        # TODO: check if we have allocated too much
        # and if so, either err or increase the available memory.
        address = bump_offset
        bump_offset = I32.add(bump_offset, size)
        address
      end

      funcp bump_free_all() do
        bump_offset = @bump_start
      end

      func alloc(size(I32)), result: I32 do
        call(:bump_alloc, size)
      end

      func free_all() do
        call(:bump_free_all)
      end
    end
  end

  defmodule MemEql do
    use Wasm

    defwasm imports: [
              env: [buffer: memory(1)]
            ] do
      funcp mem_eql_8(address_a(I32), address_b(I32)),
        result: I32,
        locals: [i: I32, byte_a: I32, byte_b: I32] do
        defloop EachChar, result: I32 do
          byte_a = memory32_8![I32.add(address_a, i)].unsigned
          byte_b = memory32_8![I32.add(address_b, i)].unsigned

          if I32.eqz(byte_a) do
            return(I32.eqz(byte_b))
          end

          if I32.eq(byte_a, byte_b) do
            i = I32.add(i, 1)
            branch(EachChar)
            # return(0x1)
          end

          return(0x0)
        end
      end

      raw_wat(~S[(export "_mem_eql_8" (func $mem_eql_8))])
    end
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

      funcp list_count(ptr(I32)), result: I32, locals: [count: I32] do
        defloop Iterate, result: I32 do
          if I32.eqz(ptr), do: return(count)

          ptr = call(:tl, ptr)
          count = I32.add(count, 1)
          branch(Iterate)
        end
      end

      funcp list32_sum(ptr(I32)), result: I32, locals: [sum: I32] do
        defloop Iterate, result: I32 do
          if I32.eqz(ptr), do: return(sum)

          sum = I32.add(sum, call(:hd, ptr))
          ptr = call(:tl, ptr)

          branch(Iterate)
        end
      end

      # export_test_func :bump_alloc
      raw_wat(~S[(export "_test_alloc" (func $bump_alloc))])
      raw_wat(~S[(export "_test_cons" (func $cons))])
      raw_wat(~S[(export "_test_hd" (func $hd))])
      raw_wat(~S[(export "_test_tl" (func $tl))])
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
