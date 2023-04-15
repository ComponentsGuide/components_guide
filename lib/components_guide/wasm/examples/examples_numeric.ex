defmodule ComponentsGuide.Wasm.Examples.Numeric do
  alias ComponentsGuide.Wasm

  defmodule UnitInterval do
    use Wasm

    defwasm do
      func to_int_in_range(value(F32), min(I32), max(I32)), result: F32 do
        # Math.floor(Math.random() * (max - min + 1)) + min
        I32.add({:i32, :trunc_f32_s, {:f32, :convert_i32_s, I32.add(I32.add(min, 1), max)}}, min)
      end
    end
  end
end
