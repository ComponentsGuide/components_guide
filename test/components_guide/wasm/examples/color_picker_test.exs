defmodule ComponentsGuide.Wasm.Examples.ColorPickerTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Examples.ColorConversion
  alias ComponentsGuide.Wasm.Examples.LabSwatch
  alias ComponentsGuideWeb.StylingHelpers

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
        {:log, :i32,
         fn value ->
           IO.inspect(value, label: "wasm log int32")
           nil
         end},
        {:log, :f32,
         fn value ->
           IO.inspect(value, label: "wasm log fnt32")
           nil
         end}
      ])

    lab_to_xyz = Instance.capture(inst, :lab_to_xyz, 3)
    lab_to_srgb = Instance.capture(inst, :lab_to_srgb, 3)
    srgb_to_linear_srgb = Instance.capture(inst, :srgb_to_linear_srgb, 3)
    linear_srgb_to_srgb = Instance.capture(inst, :linear_srgb_to_srgb, 3)
    linear_srgb_to_xyz = Instance.capture(inst, :linear_srgb_to_xyz, 3)
    xyz_to_linear_srgb = Instance.capture(inst, :xyz_to_linear_srgb, 3)
    xyz_to_srgb = Instance.capture(inst, :xyz_to_srgb, 3)

    assert lab_to_xyz.(100.0, 0.0, 0.0) === {0.9642199873924255, 1.0, 0.8252099752426147}
    assert srgb_to_linear_srgb.(1.0, 1.0, 1.0) === {1.0, 1.0, 1.0}

    assert srgb_to_linear_srgb.(0.5, 0.5, 0.5) ===
             {0.21404114365577698, 0.21404114365577698, 0.21404114365577698}

    assert linear_srgb_to_srgb.(1.0, 1.0, 1.0) ===
             {0.9999999403953552, 0.9999999403953552, 0.9999999403953552}

    assert linear_srgb_to_srgb.(0.5, 0.5, 0.5) ===
             {0.7353569269180298, 0.7353569269180298, 0.7353569269180298}

    assert StylingHelpers.convert({:linear_srgb, 0.5, 0.5, 0.5}, :srgb) ==
             {:srgb, 0.7353569830524495, 0.7353569830524495, 0.7353569830524495}

    assert StylingHelpers.convert({:lab, 100.0, 0.0, 0.0}, :xyz) == {:xyz, 0.96422, 1.0, 0.82521}

    assert StylingHelpers.convert({:linear_srgb, 0.5, 0.5, 0.5}, :xyz) ==
             {:xyz, 0.48211, 0.5, 0.412605}

    assert linear_srgb_to_xyz.(0.5, 0.5, 0.5) == {0.48210999369621277, 0.5, 0.41260501742362976}

    assert StylingHelpers.convert({:lab, 100.0, 0.0, 0.0}, :srgb) ==
             {:srgb, 0.9999999800763245, 1.0000000038208585, 1.0000000112678396}

    assert lab_to_srgb.(100.0, 0.0, 0.0) ==
             {0.9999998211860657, 0.9999999403953552, 0.9999999403953552}

    assert StylingHelpers.convert({:lab, 50.0, 0.0, -80.0}, :srgb) ==
             {:srgb, -1.4156138526821982, 0.4892403754714481, 1.0111581821308444}

    assert lab_to_srgb.(50.0, 0.0, -80.0) ==
             {0.0, 0.4892403483390808, 0.9999999403953552}
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
        {:log, :i32,
         fn value ->
           IO.inspect(value, label: "wasm log int32")
           nil
         end},
        {:log, :f32,
         fn value ->
           IO.inspect(value, label: "wasm log fnt32")
           nil
         end}
      ])

    to_html = Instance.capture(inst, String, :to_html, 0)

    assert to_html.() === ~S"""
           <div class="flex gap-4">
           <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width="160" height="160" class="touch-none" data-action data-pointerdown="l_changed" data-pointerdown+pointermove="l_changed">
           <defs>
           <linearGradient id="lab-l-gradient" gradientTransform="scale(1.414) rotate(45)">
           <stop offset="0.0%" stop-color="rgba(97.0,0.0,0.0,1)" />
           <stop offset="6.25%" stop-color="rgba(114.0,0.0,0.0,1)" />
           <stop offset="12.5%" stop-color="rgba(132.0,0.0,0.0,1)" />
           <stop offset="18.75%" stop-color="rgba(152.0,0.0,0.0,1)" />
           <stop offset="25.0%" stop-color="rgba(172.0,0.0,0.0,1)" />
           <stop offset="31.25%" stop-color="rgba(192.0,0.0,0.0,1)" />
           <stop offset="37.5%" stop-color="rgba(213.0,0.0,0.0,1)" />
           <stop offset="43.75%" stop-color="rgba(234.0,0.0,14.0,1)" />
           <stop offset="50.0%" stop-color="rgba(255.0,0.0,26.0,1)" />
           <stop offset="56.25%" stop-color="rgba(255.0,0.0,39.0,1)" />
           <stop offset="62.5%" stop-color="rgba(255.0,0.0,53.0,1)" />
           <stop offset="68.75%" stop-color="rgba(255.0,36.0,68.0,1)" />
           <stop offset="75.0%" stop-color="rgba(255.0,69.0,82.0,1)" />
           <stop offset="81.25%" stop-color="rgba(255.0,94.0,98.0,1)" />
           <stop offset="87.5%" stop-color="rgba(255.0,117.0,113.0,1)" />
           <stop offset="93.75%" stop-color="rgba(255.0,138.0,129.0,1)" />
           <stop offset="100.0%" stop-color="rgba(255.0,158.0,145.0,1)" />
           </linearGradient>
           </defs>
           <rect width="1" height="1" fill="url('#lab-l-gradient')" />
           <circle data-drag-knob="" cx="0.8799999952316284" cy="0.8799999952316284" r="0.05" fill="white" stroke="black" stroke-width="0.01" />
           </svg>
           <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width="160" height="160" class="touch-none" data-action data-pointerdown="a_changed" data-pointerdown+pointermove="a_changed">
           <defs>
           <linearGradient id="lab-a-gradient" gradientTransform="scale(1.414) rotate(45)">
           <stop offset="0.0%" stop-color="rgba(0.0,255.0,89.0,1)" />
           <stop offset="6.25%" stop-color="rgba(0.0,255.0,90.0,1)" />
           <stop offset="12.5%" stop-color="rgba(0.0,255.0,91.0,1)" />
           <stop offset="18.75%" stop-color="rgba(0.0,255.0,93.0,1)" />
           <stop offset="25.0%" stop-color="rgba(99.0,250.0,94.0,1)" />
           <stop offset="31.25%" stop-color="rgba(150.0,244.0,96.0,1)" />
           <stop offset="37.5%" stop-color="rgba(187.0,236.0,98.0,1)" />
           <stop offset="43.75%" stop-color="rgba(218.0,228.0,99.0,1)" />
           <stop offset="50.0%" stop-color="rgba(247.0,219.0,101.0,1)" />
           <stop offset="56.25%" stop-color="rgba(255.0,208.0,103.0,1)" />
           <stop offset="62.5%" stop-color="rgba(255.0,196.0,105.0,1)" />
           <stop offset="68.75%" stop-color="rgba(255.0,182.0,108.0,1)" />
           <stop offset="75.0%" stop-color="rgba(255.0,165.0,110.0,1)" />
           <stop offset="81.25%" stop-color="rgba(255.0,144.0,112.0,1)" />
           <stop offset="87.5%" stop-color="rgba(255.0,116.0,115.0,1)" />
           <stop offset="93.75%" stop-color="rgba(255.0,72.0,117.0,1)" />
           <stop offset="100.0%" stop-color="rgba(255.0,0.0,120.0,1)" />
           </linearGradient>
           </defs>
           <rect width="1" height="1" fill="url('#lab-a-gradient')" />
           <circle data-drag-knob="" cx="0.8700787425041199" cy="0.8700787425041199" r="0.05" fill="white" stroke="black" stroke-width="0.01" />
           </svg>
           <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width="160" height="160" class="touch-none" data-action data-pointerdown="b_changed" data-pointerdown+pointermove="b_changed">
           <defs>
           <linearGradient id="lab-b-gradient" gradientTransform="scale(1.414) rotate(45)">
           <stop offset="0.0%" stop-color="rgba(255.0,143.0,255.0,1)" />
           <stop offset="6.25%" stop-color="rgba(255.0,140.0,255.0,1)" />
           <stop offset="12.5%" stop-color="rgba(255.0,137.0,255.0,1)" />
           <stop offset="18.75%" stop-color="rgba(255.0,134.0,255.0,1)" />
           <stop offset="25.0%" stop-color="rgba(255.0,131.0,255.0,1)" />
           <stop offset="31.25%" stop-color="rgba(255.0,128.0,255.0,1)" />
           <stop offset="37.5%" stop-color="rgba(255.0,126.0,255.0,1)" />
           <stop offset="43.75%" stop-color="rgba(255.0,124.0,255.0,1)" />
           <stop offset="50.0%" stop-color="rgba(255.0,123.0,226.0,1)" />
           <stop offset="56.25%" stop-color="rgba(255.0,121.0,197.0,1)" />
           <stop offset="62.5%" stop-color="rgba(255.0,120.0,168.0,1)" />
           <stop offset="68.75%" stop-color="rgba(255.0,119.0,138.0,1)" />
           <stop offset="75.0%" stop-color="rgba(255.0,118.0,108.0,1)" />
           <stop offset="81.25%" stop-color="rgba(255.0,118.0,74.0,1)" />
           <stop offset="87.5%" stop-color="rgba(255.0,117.0,25.0,1)" />
           <stop offset="93.75%" stop-color="rgba(255.0,117.0,0.0,1)" />
           <stop offset="100.0%" stop-color="rgba(255.0,117.0,0.0,1)" />
           </linearGradient>
           </defs>
           <rect width="1" height="1" fill="url('#lab-b-gradient')" />
           <circle data-drag-knob="" cx="0.7362204790115356" cy="0.7362204790115356" r="0.05" fill="white" stroke="black" stroke-width="0.01" />
           </svg>
           </div>
           <output class="flex mt-4"><pre>
           lab(88.0% 94.0 60.0)
           rgb(255.0 118.0 114.0)
           </pre></output>
           """
  end
end
