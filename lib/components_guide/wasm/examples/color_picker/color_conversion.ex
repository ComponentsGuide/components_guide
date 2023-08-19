defmodule ComponentsGuide.Wasm.Examples.ColorConversion do
  require Orb.DSL
  use Orb

  @xn 0.96422
  @yn 1.00000
  @zn 0.82521
  @k :math.pow(29, 3) / :math.pow(3, 3)
  @e :math.pow(6, 3) / :math.pow(29, 3)

  # TODO: check against CSS’s https://www.w3.org/TR/css-color-4/#color-conversion-code

  # F32.global(:readonly, e: :math.pow(6, 3) / :math.pow(29, 3))

  # Import.module :math do
  #   defwp powf32(x: F32, y: F32), F32
  # end
  # Import.module :log do
  #   defwp i32(x: F32, y: F32), F32, as: :log_i32
  # end

  wasm_import(:math,
    powf32: Orb.DSL.funcp(name: :powf32, params: {F32, F32}, result: F32)
  )
  wasm_import(:log,
    i32: Orb.DSL.funcp(name: :log_i32, params: I32),
    f32: Orb.DSL.funcp(name: :log_f32, params: F32)
  )

  wasm F32 do
    funcp lab_to_xyz_component(v: F32), F32, cubed: F32 do
      cubed = call(:powf32, v, 3.0)

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

    funcp xyz_to_lab_component(c: F32), F32 do
      if c > ^@e, result: F32 do
        call(:powf32, c, 1.0 / 3.0)
      else
        (^@k * c + 16.0) / 116.0
      end
    end

    func xyz_to_lab(x: F32, y: F32, z: F32), {F32, F32, F32}, f0: F32, f1: F32, f2: F32 do
      f0 = call(:xyz_to_lab_component, x / ^@xn)
      f1 = call(:xyz_to_lab_component, y / ^@yn)
      f2 = call(:xyz_to_lab_component, z / ^@zn)

      116.0 * f1 - 16.0
      500.0 * (f0 - f1)
      200.0 * (f1 - f2)
    end

    func linear_srgb_to_srgb(r: F32, g: F32, b: F32), {F32, F32, F32} do
      call(:linear_srgb_to_srgb_component, r)
      call(:linear_srgb_to_srgb_component, g)
      call(:linear_srgb_to_srgb_component, b)
    end

    funcp linear_srgb_to_srgb_component(c: F32), F32 do
      if c > 0.0031308, result: F32 do
        1.055 * call(:powf32, c, 1.0 / 2.4) - 0.055
      else
        12.92 * c
      end
    end

    func srgb_to_linear_srgb(r: F32, g: F32, b: F32), {F32, F32, F32} do
      call(:srgb_to_linear_srgb_component, r)
      call(:srgb_to_linear_srgb_component, g)
      call(:srgb_to_linear_srgb_component, b)
    end

    funcp srgb_to_linear_srgb_component(c: F32), F32 do
      if c < 0.04045, result: F32 do
        c / 12.92
      else
        call(:powf32, (c + 0.055) / 1.055, 2.4)
      end
    end

    func xyz_to_linear_srgb(x: F32, y: F32, z: F32), {F32, F32, F32} do
      # TODO: decide whether to clamp here
      # https://github.com/d3/d3-color/issues/33
      (x * 3.1338561 - y * 1.6168667 - 0.4906146 * z) |> F32.min(1.0) |> F32.max(0.0)
      (x * -0.9787684 + y * 1.9161415 + 0.0334540 * z) |> F32.min(1.0) |> F32.max(0.0)
      (x * 0.0719453 - y * 0.2289914 + 1.4052427 * z) |> F32.min(1.0) |> F32.max(0.0)
    end

    func xyz_to_srgb(x: F32, y: F32, z: F32), {F32, F32, F32} do
      call(:xyz_to_linear_srgb, x, y, z)
      call(:linear_srgb_to_srgb)
    end

    func linear_srgb_to_xyz(r: F32, g: F32, b: F32), {F32, F32, F32} do
      0.4360747 * r + 0.3850649 * g + 0.1430804 * b
      0.2225045 * r + 0.7168786 * g + 0.0606169 * b
      0.0139322 * r + 0.0971045 * g + 0.7141733 * b
    end

    func srgb_to_xyz(r: F32, g: F32, b: F32), {F32, F32, F32} do
      # TODO: {r, g, b} |> srgb_to_linear_srgb() |> linear_srgb_to_xyz()
      call(:srgb_to_linear_srgb, r, g, b)
      call(:linear_srgb_to_xyz)
    end

    func lab_to_srgb(l: F32, a: F32, b: F32), {F32, F32, F32} do
      call(:lab_to_xyz, l, a, b)
      call(:xyz_to_srgb)
    end

    func srgb_to_lab(r: F32, g: F32, b: F32), {F32, F32, F32} do
      call(:srgb_to_xyz, r, g, b)
      call(:xyz_to_lab)
    end
  end
end
