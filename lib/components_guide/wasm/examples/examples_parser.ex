defmodule ComponentsGuide.Wasm.Examples.Parser do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

  defmodule HexConversion do
    use Wasm

    @wasm_memory 2

    wasm do
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
