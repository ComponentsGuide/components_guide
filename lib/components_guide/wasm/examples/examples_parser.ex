defmodule ComponentsGuide.Wasm.Examples.Parser do
  alias ComponentsGuide.Wasm

  defmodule HexConversion do
    use Wasm

    # memory :export, min: 1
    # @wasm_memory export?: true, min: 1

    # defwasm exported_memory: 1 do
    defwasm imports: [env: [buffer: memory(2)]] do
      func i32_to_hex_lower(value(I32), write_to_address(I32)), locals: [i: I32, digit: I32] do
        i = 8

        defloop Digits do
          i = I32.sub(i, 1)

          digit = I32.rem_u(value, 16)
          value = I32.div_u(value, 16)

          if I32.gt_u(digit, 9) do
            memory32_8![I32.add(write_to_address, i)] = I32.add(?a, I32.sub(digit, 10))
          else
            memory32_8![I32.add(write_to_address, i)] = I32.add(?0, digit)
          end

          branch(Digits, if: I32.gt_u(i, 0))
        end
      end
    end
  end
end
