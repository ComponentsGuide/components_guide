defmodule ComponentsGuide.Wasm.Examples.ColorPickerTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Examples.ColorConversion

  alias OrbWasmtime.Instance

  test "ColorConversion" do
    inst = Instance.run(ColorConversion, [
      {:math, :powf32,
         fn x, y ->
           Float.pow(x, y)
         end},
      # {:math, :f32,
      #    fn x ->
      #      1.0
      #    end}
      {:log, :int32,
         fn value ->
           IO.inspect(value, label: "wasm log int32")
           0
         end}
    ])
    lab_to_xyz = Instance.capture(inst, :lab_to_xyz, 3)
    assert lab_to_xyz.(100.0, 0.0, 0.0) === {0.9642199873924255, 1.0, 0.8252099752426147}
  end
end
