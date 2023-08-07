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
    # IO.puts(LabSwatch.to_wat())
    assert is_binary(LabSwatch.to_wasm())
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
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width="160" height="160" data-color-property="l">
    <defs>
    <linearGradient id="lab-l-gradient" gradientTransform="scale(1.414) rotate(45)">
    <stop offset="0.0%" stop-color="rgba(195.0,0.0,0.0,1)" />
    <stop offset="25.0%" stop-color="rgba(255.0,0.0,59.0,1)" />
    <stop offset="50.0%" stop-color="rgba(255.0,0.0,162.0,1)" />
    <stop offset="75.0%" stop-color="rgba(255.0,91.0,247.0,1)" />
    <stop offset="100.0%" stop-color="rgba(255.0,171.0,255.0,1)" />
    </linearGradient>
    </defs>
    <rect width="1" height="1" fill="url('#lab-l-gradient')" />
    <circle data-drag-knob="" cx="0.5" cy="0.5" r="0.05" fill="white" stroke="black" stroke-width="0.01" />
    </svg>
    """
  end
end
