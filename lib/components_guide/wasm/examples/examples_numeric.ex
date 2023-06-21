defmodule ComponentsGuide.Wasm.Examples.Numeric do
  alias ComponentsGuide.Wasm

  defmodule BasicMath do
    use Wasm

    defwasm do
      func i32_double(value(I32)), I32 do
        I32.mul(value, 2)
      end

      func f32_double(value(F32)), F32 do
        F32.mul(value, 2.0)
      end
    end
  end

  defmodule UnitInterval do
    use Wasm

    defwasm do
      func to_int_in_range(value(F32), min(I32), max(I32)), I32 do
        # Math.floor(Math.random() * (max - min + 1)) + min
        I32.add(
          I32.trunc_f32_s(
            F32.mul(
              value,
              I32.sub(max, min) |> I32.add(1) |> F32.convert_i32_s()
              # F32.convert_i32_s(I32.math do: max - min + 1))
            )
          ),
          min
        )
      end
    end
  end
end
