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

  defmodule LinkedLists do
    use Wasm

    @page_size 64 * 1024
    @bump_start 1 * @page_size

    defwasm imports: [
              env: [buffer: memory(1)],
              log: [
                int32: func(name: :log32, params: I32, result: I32)
              ]
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
        # call(:log32, ptr)
        I32.if_eqz(ptr, do: 0x0, else: memory32![I32.add(ptr, 4)])
        # 0x0
        # memory32![I32.add(ptr, 1)]
        # :return
      end

      funcp count(ptr(I32)), result: I32, locals: [count: I32] do
        defloop Iterate, result: I32 do
          if I32.eqz(ptr), do: return(count)

          ptr = call(:tl, ptr)
          # ptr = memory32![I32.add(ptr, 1)]
          count = I32.add(count, 1)
          branch(Iterate)

          # 0x2
        end

        # if I32.eqz(ptr), do: return(count)

        # 0x1
      end

      # export_test_func :bump_alloc
      raw_wat(~S[(export "_test_alloc" (func $bump_alloc))])
      raw_wat(~S[(export "_test_cons" (func $cons))])
      raw_wat(~S[(export "_test_hd" (func $hd))])
      raw_wat(~S[(export "_test_tl" (func $tl))])
      raw_wat(~S[(export "_test_count" (func $count))])
    end

    def start(_init) do
      imports = [
        {:log, :int32, fn value ->
          IO.inspect(value, label: "wasm log int32")
          0
        end}
      ]

      IO.inspect(imports)

      ComponentsGuide.Wasm.run_instance(__MODULE__, imports)
    end

    def capture(inst, :_test_alloc, 1) do
      fn size ->
        Wasm.Instance.call(inst, :_test_alloc, size)
      end
    end

    def capture(inst, :_test_cons, 2) do
      fn hd, tl ->
        Wasm.Instance.call(inst, :_test_cons, hd, tl)
      end
    end

    def capture(inst, :_test_count, 1) do
      fn ptr ->
        Wasm.Instance.call(inst, :_test_count, ptr)
      end
    end
  end
end
