defmodule ComponentsGuide.Wasm.Examples.ColorConversion do
  require Orb.DSL
  use Orb

  @xn 0.96422
  @yn 1.00000
  @zn 0.82521
  @k :math.pow(29, 3) / :math.pow(3, 3)
  @e :math.pow(6, 3) / :math.pow(29, 3)

  wasm_import(:math,
    powf32: Orb.DSL.funcp(name: :powf32, params: {F32, F32}, result: F32)
  #   # powf32: Orb.DSL.funcp(name: :powf32, params: F32, result: F32)
  #   i32: Orb.DSL.funcp(name: :i32, params: I32, result: I32)
  #   # f32: Orb.DSL.funcp(name: :f32, params: F32, result: F32)
  )
  wasm_import(:log, int32: Orb.DSL.funcp(name: :log32, params: I32, result: I32))

  wasm F32 do
    # Copied from: https://augustus-pash.gitbook.io/wasm/maths-algorithms/aprox-sin
    funcp pow(base: F32, exponent: F32), F32, out: F32, index: F32 do
      out = 1.0
      index = 1.0

      defblock Outer do
        loop Inner do
          out = out * base

          index = index + 1.0
          break(Outer, if: index > exponent)

          Inner.continue()
        end
      end

      out
    end

    funcp lab_to_xyz_component(v: F32), F32, cubed: F32 do
      cubed = call(:pow, v, 3.0)

      if cubed > ^@e, result: F32 do
        cubed
      else
        (116.0 * v - 16.0) / ^@k
      end
    end

    func lab_to_xyz(l: F32, a: F32, b: F32), {F32, F32, F32}, fy: F32, fx: F32, fz: F32 do
      fy = (l + 16.0) / 116.0
      fx = a / 500.0 + fy
      fz = fy - b / 200.0

      call(:lab_to_xyz_component, fx) * ^@xn
      call(:lab_to_xyz_component, fy) * ^@yn
      call(:lab_to_xyz_component, fz) * ^@zn
    end

    func srgb_to_linear_rgb_component(c: F32), F32 do
      if c < 0.04045, result: F32 do
        c / 12.92
      else
        call(:powf32, (c + 0.055) / 1.055, 2.4)
      end
    end
  end
end
