defmodule ComponentsGuide.Wasm.Examples.ColorPickerTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Examples.ColorConversion

  alias OrbWasmtime.Instance

  test "ColorConversion" do
    inst = Instance.run(ColorConversion)
  end
end
