defmodule ComponentsGuide.Wasm.Examples.Parser do
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

  defmodule HexConversion do
    use Orb

    # @wasm_memory 1
    # Memory.increase! pages: 1
    Memory.pages(1)

    wasm U32 do
      func u32_to_hex_lower(
             value: I32,
             write_ptr: I32.U8.Pointer
           ),
           i: I32,
           digit: I32 do
        i = 8

        loop Digits do
          i = i - 1

          digit = I32.rem_u(value, 16)
          value = value / 16

          if digit > 9 do
            write_ptr[at!: i] = ?a + digit - 10
          else
            write_ptr[at!: i] = ?0 + digit
          end

          Digits.continue(if: i > 0)
        end
      end
    end

    def u32_to_hex_lower(value, write_to_address) do
      Orb.DSL.call(:u32_to_hex_lower, value, write_to_address)
    end
  end

  defmodule DomainNames do
    use Orb
    use BumpAllocator
    use I32.String

    wasm do
      func(alloc(byte_size(I32)), I32, do: call(:bump_alloc, byte_size))

      func lookup_domain_name(value(I32.String)), I32 do
        I32.String.match value do
          ~S"com" -> 1
          ~S"org" -> 1
          _ -> 0
        end
      end
    end
  end
end
