defmodule ComponentsGuide.Wasm.Examples.ColorPickerTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Examples.ColorConversion
  alias ComponentsGuide.Wasm.Examples.LabSwatch

  alias OrbWasmtime.Instance

  test "ColorConversion" do
    inst =
      Instance.run(ColorConversion, [
        {:math, :powf32,
         fn x, y ->
           Float.pow(x, y)
         end},
        {:format, :f32,
         fn caller, f, memory_offset ->
          formatted = Float.to_string(f)
          len = Instance.Caller.write_string_nul_terminated(caller, memory_offset, formatted)
          # Minus nul-terminator. Maybe write_string_nul_terminated shouldn’t include that in the length?
          len - 1
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
    srgb_to_linear_rgb = Instance.capture(inst, :srgb_to_linear_rgb, 3)
    linear_rgb_to_srgb = Instance.capture(inst, :linear_rgb_to_srgb, 3)
    xyz_to_linear_rgb = Instance.capture(inst, :xyz_to_linear_rgb, 3)
    xyz_to_srgb = Instance.capture(inst, :xyz_to_srgb, 3)

    assert lab_to_xyz.(100.0, 0.0, 0.0) === {0.9642199873924255, 1.0, 0.8252099752426147}
    assert srgb_to_linear_rgb.(1.0, 1.0, 1.0) === {1.0, 1.0, 1.0}
    assert srgb_to_linear_rgb.(0.5, 0.5, 0.5) === {0.21404114365577698, 0.21404114365577698, 0.21404114365577698}
    assert linear_rgb_to_srgb.(1.0, 1.0, 1.0) === {0.9999999403953552, 0.9999999403953552, 0.9999999403953552}
    assert linear_rgb_to_srgb.(0.5, 0.5, 0.5) === {0.7353569269180298, 0.7353569269180298, 0.7353569269180298}
  end

  test "LabSwatch" do
    IO.puts(LabSwatch.to_wat())
    inst =
      Instance.run(LabSwatch, [
        {:math, :powf32,
         fn x, y ->
           Float.pow(x, y)
         end},
        {:format, :f32,
         fn caller, f, memory_offset ->
          formatted = Float.to_string(f)
          len = Instance.Caller.write_string_nul_terminated(caller, memory_offset, formatted)
          # Minus nul-terminator. Maybe write_string_nul_terminated shouldn’t include that in the length?
          len - 1
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

    to_svg = Instance.capture(inst, String, :to_svg, 0)

    assert to_svg.() === ~S"""
    <linearGradient id="lab-l-gradient" gradientTransform="scale(1.414) rotate(45)">
    <stop offset="0.0" stop-color="rgba(0.0,0.0,0.0,1)" />
    <stop offset="100.0" stop-color="rgba(255.0,255.0,255.0,1)" />
    </linearGradient>
    """
  end
end
