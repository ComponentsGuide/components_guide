defmodule ComponentsGuide.Wasm.Examples.LabSwatch do
  use Orb
  use ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  use ComponentsGuide.Wasm.Examples.StringBuilder
  alias ComponentsGuide.Wasm.Examples.ColorConversion

  # Import.funcp({:math, :powf32}, as: :powf32, params: {F32, F32}, result: F32)
  # Import.funcp({:format, :f32}, as: :format_f32, params: {F32, I32}, result: I32)

  # wasm_import :math do
  #   funcp powf32(x: F32, y: F32), F32
  # end
  # wasm_import :format do
  #   funcp :f32, format_f32(f: F32, ptr: I32), I32
  # end

  wasm_import(:math,
    powf32: Orb.DSL.funcp(name: :powf32, params: {F32, F32}, result: F32)
  )

  wasm_import(:format,
    f32: Orb.DSL.funcp(name: :format_f32, params: {F32, I32}, result: I32)
  )

  # I32.export_global(:mutable, l: 50)

  I32.enum([:swatch_l, :swatch_a, :swatch_b])

  wasm do
    ColorConversion.funcp()

    # import_funcp :math, powf32(x: F32, y: F32), F32

    func to_svg(), I32.String do
      build! do
        append!(:swatch_svg, @swatch_l)
      end
    end

    func swatch_svg(swatch: I32), I32.String do
      build! do
        append!(
          ~S(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width="160" height="160" data-color-property="l">\n)
        )

        append!(~S(<defs>\n))
        append!(:do_linear_gradient)
        append!(~S(</defs>\n))
        append!(~S{<rect width="1" height="1" fill="url('#lab-l-gradient')" />\n})

        # append!(~S{<circle data-drag-knob cx="<%= l / 100.0 %>" cy="<%= l / 100.0 %>" r="0.05" fill="white" stroke="black" stroke-width="0.01" />})
        append!(
          ~S{<circle data-drag-knob="" cx="0.5" cy="0.5" r="0.05" fill="white" stroke="black" stroke-width="0.01" />\n}
        )

        append!(~S{</svg>\n})
      end
    end

    funcp do_linear_gradient(), I32.String, i: I32 do
      build! do
        append!(
          string: ~S{<linearGradient id="},
          string: ~S{lab-l-gradient},
          string: ~S{" gradientTransform="scale(1.414) rotate(45)">\n}
        )

        loop Stops do
          i = i + 1
          Stops.continue(if: i < 20)
        end

        append!(:do_linear_gradient_stop, [0.0, 0.0, 0.0, 0.0])
        append!(:do_linear_gradient_stop, [0.25, 25.0, 0.0, 0.0])
        append!(:do_linear_gradient_stop, [0.5, 50.0, 0.0, 0.0])
        append!(:do_linear_gradient_stop, [0.75, 75.0, 0.0, 0.0])
        append!(:do_linear_gradient_stop, [1.0, 100.0, 0.0, 0.0])
        append!(~S{</linearGradient>\n})
      end
    end
  end

  wasm F32 do
    funcp do_linear_gradient_stop(fraction: F32, l: F32, a: F32, b: F32), I32,
      red: F32,
      green: F32,
      blue: F32 do
      # percentage = "#{index / max * 100}%"

      # call(:linear_rgb_to_srgb, r, g, b)
      # call(:srgb_to_linear_rgb, r, g, b)
      call(:lab_to_srgb, l, a, b)
      local_set(:red)
      local_set(:green)
      local_set(:blue)

      build! do
        append!(~S{<stop offset="})
        append!(decimal_f32: fraction * 100.0)
        append!(~S{%" stop-color="})
        append!(~S{rgba(})
        append!(decimal_f32: F32.nearest(red * 255.0))
        append!(~S{,})
        append!(decimal_f32: F32.nearest(green * 255.0))
        append!(~S{,})
        append!(decimal_f32: F32.nearest(blue * 255.0))
        append!(~S{,1)})
        append!(~S{" />\n})
      end

      # xml = ~E"""
      # <stop offset="<%= percentage %>" stop-color="<%= to_css(color, :srgb) %>" />
      # """
    end
  end

  @wasm File.read!(Path.join(__DIR__, "lab_swatch.wasm"))

  def to_wasm() do
    @wasm
  end
end
