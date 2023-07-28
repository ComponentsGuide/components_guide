defmodule ComponentsGuide.Wasm.Examples.ColorPickerTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Examples.ColorConversion

  alias OrbWasmtime.Instance

  test "ColorConversion" do
    inst = Instance.run(ColorConversion)
    lab_to_xyz = Instance.capture(inst, :lab_to_xyz, 3)
    assert lab_to_xyz.(100.0, 0.0, 0.0) === {0.9642199873924255, 1.0, 0.8252099752426147}
  end
end
