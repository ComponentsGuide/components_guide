defmodule ComponentsGuide.Wasm.Examples.Memory do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.WasmBuilder

  defmodule Copying do
    use WasmBuilder

    defmacro __using__(_opts) do
      quote do
        # @wasm_memory 1

        import WasmBuilder

        wasm do
          unquote(__MODULE__).funcp(:memcpy)
        end

        import unquote(__MODULE__)
      end
    end

    @wasm_memory 2

    wasm do
      func memcpy(dest(I32), src(I32), byte_count(I32)),
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
    end

    def memcpy(dest, src, byte_count) do
      call(:memcpy, dest, src, byte_count)
    end
  end

  defmodule BumpAllocator do
    defmodule Constants do
      @page_size 64 * 1024
      @bump_start 1 * @page_size
      def bump_init_offset(), do: @bump_start
    end

    # require Constants

    use WasmBuilder
    import ComponentsGuide.Wasm.Examples.Memory.Copying

    # defmacro bump_offset(), do: Macro.escape(Module.get_attribute(__MODULE__, :bump_start))

    defmacro __using__(opts \\ []) do
      quote do
        @wasm_memory 2
        # @wasm_global {:bump_offset, i32(BumpAllocator.bump_offset())}

        import ComponentsGuide.WasmBuilder

        global(
          bump_offset: i32(Constants.bump_init_offset()),
          bump_mark: i32(0)
        )

        use ComponentsGuide.Wasm.Examples.Memory.Copying

        ComponentsGuide.WasmBuilder.wasm do
          unquote(__MODULE__).funcp(:bump_alloc)
        end

        if unquote(opts[:export]) do
          ComponentsGuide.WasmBuilder.wasm do
            func alloc(size(I32)), I32 do
              call(:bump_alloc, local_get(:size))
            end
          end
        end

        import unquote(__MODULE__)
      end
    end

    @wasm_memory 2

    global(
      bump_offset: i32(Constants.bump_init_offset()),
      bump_mark: i32(0)
    )

    wasm do
      funcp bump_alloc(size(I32)), I32, address: I32 do
        # TODO: check if we have allocated too much
        # and if so, either err or increase the available memory.
        # TODO: Need better maths than this to round up to aligned memory?
        address = @bump_offset
        @bump_offset = I32.add(@bump_offset, size)
        address
      end

      funcp bump_free_all() do
        @bump_offset = Constants.bump_init_offset()
      end

      func alloc(size(I32)), result: I32 do
        call(:bump_alloc, size)
      end

      func free_all() do
        call(:bump_free_all)
      end
    end

    def write_start!() do
      snippet do
        @bump_mark = @bump_offset
      end
    end

    def write_done!() do
      snippet do
        bump_write!(ascii: 0x0)

        @bump_mark
      end
    end

    def bump_write!(ascii: char) do
      snippet do
        memory32_8![@bump_offset] = char
        @bump_offset = I32.add(@bump_offset, 1)
      end
    end

    def bump_write!(hex_upper: hex) do
      # This might be a bit over the top…
      {initial, following} = case hex do
        [value, {:local_tee, identifier}] ->
          {hex, {:local_get, identifier}}
          
        _ ->
          {hex, hex}
      end
      
      snippet do
        # push(hex)
        # 
        # push(I32.le_u(hex, 9))
        # 
        # :drop
        # 
        # :pop
        
        # memory32_8![@bump_offset] = I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))
        
        # I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))
        
        # push(@bump_offset)
        # push(@bump_offset)
        
        # memory32_8![0x0] = hex
        # if I32.le_u(memory32_8![0x0].unsigned, 9) do
        #   memory32_8![@bump_offset] = I32.add(memory32_8![0x0].unsigned, ?0)
        # else
        #   memory32_8![@bump_offset] = I32.sub(memory32_8![0x0].unsigned, 10) |> I32.add(?A)
        # end
        
        # I32.when? I32.le_u(:pop, 9) do
        #   push(hex)
        #   I32.add(:pop, ?0)
        # else
        #   push(hex)
        #   I32.sub(:pop, 10) |> I32.add(?A)
        # end
        # memory32_8![:pop] = :pop
        
        # FIXME: we are evaluating hex multiple times. Do we have to stash it in a variable?
        memory32_8![@bump_offset] =
          I32.when?(I32.le_u(initial, 9), do: I32.add(following, ?0), else: I32.sub(following, 10) |> I32.add(?A))
        
        # memory32_8![@bump_offset] =
        #   I32.when?(I32.le_u(initial, 9), do: I32.add(following, ?0), else: I32.sub(following, 10) |> I32.add(?A))
        
        # memory32_8![@bump_offset] =
        #   I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))

        @bump_offset = I32.add(@bump_offset, 1)
      end
    end
    
#     def bump_write!(list) when is_list(list) do
#       snippet do
#         inline for item <- list do
#           # WE NEED TO INCREMENT bump_offset after each round
#           case item do
#             {:ascii, char} ->
#               snippet do
#                 memory32_8![@bump_offset] = char
#               end
#               
#             {:hex_upper, hex} ->
#               snippet do
#                 memory32_8![@bump_offset] =
#                   I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))
#               end
#           end
#         end
# 
#         @bump_offset = I32.add(@bump_offset, length(list))
#       end |> dbg()
#     end

    def join!(list!) when is_list(list!) do
      alias ComponentsGuide.Wasm.Examples.Memory.Copying

      snippet do
        global_get(:bump_offset)
        global_set(:bump_mark)

        inline for item! <- list! do
          case item! do
            {:i32_const_string, strptr, string} ->
              [
                Copying.memcpy(global_get(:bump_offset), strptr, byte_size(string)),
                I32.add(global_get(:bump_offset), byte_size(string)),
                global_set(:bump_offset)
              ]

            strptr ->
              [
                Copying.memcpy(global_get(:bump_offset), strptr, call(:strlen, strptr)),
                I32.add(global_get(:bump_offset), call(:strlen, strptr)),
                global_set(:bump_offset)
              ]
          end
        end

        # Add nul-terminator
        I32.add(global_get(:bump_offset), 1)
        global_set(:bump_offset)
        # @bump_offset = I32.add(@bump_offset, 1)

        global_get(:bump_mark)
      end
    end

    def alloc(byte_count) do
      call(:bump_alloc, byte_count)
    end

    # def memcpy(dest, {:const_string, string}) do
    #   call(:bump_memcpy, dest, src, byte_count(string))
    # end
  end

  defmodule LinkedLists do
    use Wasm
    use BumpAllocator

    defmacro __using__(_opts) do
      quote do
        # @wasm_memory 1

        import WasmBuilder

        wasm do
          unquote(__MODULE__).funcp(:cons)
          unquote(__MODULE__).funcp(:hd)
          unquote(__MODULE__).funcp(:tl)
          unquote(__MODULE__).funcp(:reverse)
        end

        import unquote(__MODULE__)
      end
    end

    # increase_memory pages: 2
    @wasm_memory 2

    defwasm do
      func cons(hd(I32), tl(I32)), result: I32, locals: [ptr: I32] do
        ptr = call(:bump_alloc, 8)
        memory32![ptr] = hd
        memory32![I32.add(ptr, 4)] = tl
        ptr
      end

      func hd(ptr(I32)), result: I32 do
        I32.if_eqz(ptr, do: 0x0, else: memory32![ptr])
        # I32.eqz(ptr) |> I32.if_else(do: 0x0, else: memory32![ptr])
      end

      func tl(ptr(I32)), result: I32 do
        I32.if_eqz(ptr, do: 0x0, else: memory32![I32.add(ptr, 4)])
      end

      func reverse(node(I32)), result: I32, locals: [prev: I32, current: I32, next: I32] do
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

      func list_count(ptr(I32)), result: I32, locals: [count: I32] do
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
          count = I32.add(count, 1)
          Iterate.continue()
        end
      end

      func list32_sum(ptr(I32)), result: I32, locals: [sum: I32] do
        loop Iterate, result: I32 do
          if I32.eqz(ptr), do: return(sum)

          sum = I32.add(sum, call(:hd, ptr))
          ptr = call(:tl, ptr)

          Iterate.continue()
        end
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

      ComponentsGuide.Wasm.run_instance(__MODULE__, imports)
    end
  end
end
