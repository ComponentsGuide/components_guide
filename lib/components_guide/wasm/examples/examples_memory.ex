defmodule ComponentsGuide.Wasm.Examples.Memory do
  defmodule LinkedLists do
    alias OrbWasmtime.Instance
    use Orb
    use SilverOrb.BumpAllocator

    defmacro __using__(_opts) do
      quote do
        # @wasm_memory 1

        import Orb

        wasm do
          unquote(__MODULE__).funcp(:cons)
          unquote(__MODULE__).funcp(:hd)
          unquote(__MODULE__).funcp(:tl)
          unquote(__MODULE__).funcp(:reverse_in_place)
        end

        import unquote(__MODULE__)
      end
    end

    # increase_memory pages: 2
    # @wasm_memory 2

    wasm U32 do
      func cons(hd: I32.UnsafePointer, tl: I32.UnsafePointer), I32.UnsafePointer, ptr: I32.UnsafePointer do
        ptr = call(:bump_alloc, 8)
        ptr[at!: 0] = hd
        ptr[at!: 1] = tl
        ptr
      end

      func hd(ptr: I32.UnsafePointer), I32.UnsafePointer do
        # Zig: https://godbolt.org/z/bG5zj6bzx
        # ptr[at: 0, fallback: 0x0]
        I32.eqz(ptr) |> I32.when?(do: 0x0, else: ptr[at!: 0])
        # ptr &&& ptr[at!: 0]
        # ptr[at!: 0]
      end

      func tl(ptr: I32.UnsafePointer), I32.UnsafePointer do
        # ptr.unwrap[at!: 1]
        # ptr |> I32.eqz?(do: :unreachable, else: ptr[at!: 1])
        I32.eqz(ptr) |> I32.when?(do: 0x0, else: ptr[at!: 1])
        # ptr[at!: 1]
      end

      func reverse_in_place(node: I32.UnsafePointer), I32.UnsafePointer,
        prev: I32.UnsafePointer,
        current: I32.UnsafePointer,
        next: I32.UnsafePointer do
        current = node

        # loop current, result: I32 do
        #   0 ->
        #     {:halt, prev}
        #
        #   current ->
        #     next = current[at!: 1]
        #     current[at!: 1] = prev
        #     prev = current
        #     {:cont, next}
        # end

        loop Iterate, result: I32 do
          # return(prev, if: I32.eqz(current))
          if I32.eqz(current), do: return(prev)

          next = current[at!: 1]
          current[at!: 1] = prev
          prev = current
          current = next
          Iterate.continue()
        end
      end

      func list_count(ptr: I32.UnsafePointer), I32, count: I32 do
        loop Iterate, result: I32 do
          #           I32.match ptr do
          #             0 ->
          #               return(count)
          #
          #             _ ->
          #               ptr = call(:tl, ptr)
          #               count = I32.add(count, 1)
          #               Iterate.continue()
          #           end

          if I32.eqz(ptr), do: return(count)
          # if I32.eqz(ptr), return: count
          # return(count, if: I32.eqz(ptr))
          # guard ptr, else_return: count
          # I32.unless ptr, return: count
          # I32.when? ptr, else_return: count
          # I32.when? ptr, else: return(count)

          ptr = call(:tl, ptr)
          count = count + 1
          Iterate.continue()
        end
      end

      func list32_sum(ptr(I32)), I32, sum: I32 do
        loop Iterate, result: I32 do
          if I32.eqz(ptr), do: return(sum)

          sum = sum + call(:hd, ptr)
          ptr = call(:tl, ptr)

          Iterate.continue()
        end
      end
    end

    def cons(head, tail) do
      snippet U32 do
        call(:cons, head, tail)
      end
    end

    def hd!(ptr) do
      snippet U32 do
        # I32.load(ptr)
        Memory.load!(I32, ptr)
      end
    end

    def tl!(ptr) do
      snippet U32 do
        # I32.load(ptr + 4)
        Memory.load!(I32, ptr + 4)
      end
    end

    def reverse_in_place!(%Orb.MutRef{read: read, write: write}) do
      snippet U32 do
        call(:reverse_in_place, read)
        write
      end
    end

    def start() do
      imports = [
        {:log, :int32,
         fn value ->
           IO.inspect(value, label: "wasm log int32")
           0
         end}
      ]

      Instance.run(__MODULE__, imports)
    end
  end
end
