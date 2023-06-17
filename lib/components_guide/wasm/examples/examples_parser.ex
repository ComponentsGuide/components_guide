defmodule ComponentsGuide.Wasm.Examples.Parser do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.MemEql
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

  defmodule HexConversion do
    use Wasm

    @wasm_memory 2

    # memory :export, min: 1
    # @wasm_memory export?: true, min: 1

    # defwasm exported_memory: 1 do
    defwasm do
      func i32_to_hex_lower(value(I32), write_to_address(I32)), locals: [i: I32, digit: I32] do
        # func i32_to_hex_lower(value: I32, write_to_address: I32), locals: [i: I32, digit: I32] do
        i = 8

        loop Digits do
          i = I32.sub(i, 1)

          digit = I32.rem_u(value, 16)
          value = I32.div_u(value, 16)

          if I32.gt_u(digit, 9) do
            memory32_8![I32.add(write_to_address, i)] = I32.add(?a, I32.sub(digit, 10))
          else
            memory32_8![I32.add(write_to_address, i)] = I32.add(?0, digit)
          end

          Digits.continue(if: I32.gt_u(i, 0))
        end
      end
    end

    def i32_to_hex_lower(value, write_to_address) do
      call(:i32_to_hex_lower, value, write_to_address)
    end
  end

  defmodule DomainNames do
    use Wasm

    # memory :export, min: 1
    # @wasm_memory export?: true, min: 1

    @page_size 64 * 1024
    @bump_start 1 * @page_size

    @wasm_memory 1

    # @wasm_global bump_offset: i32(@bump_start)
    @wasm_global {:bump_offset, i32(@bump_start)}

    defwasm do
      MemEql.funcp(:mem_eql_8)
      BumpAllocator.funcp(:bump_alloc)

      func alloc(byte_size(I32)), I32 do
        # Need better maths than this to round up to aligned memory?
        # BumpAllocator.call(:bump_alloc, byte_size)
        call(:bump_alloc, byte_size)
      end

      func lookup_domain_name(value(I32)), I32 do
        # MemEql.call(:mem_eql_8, value, const("com"))
        # call(:mem_eql_8, value, const("com"))
        0x0
      end
    end
  end
end
