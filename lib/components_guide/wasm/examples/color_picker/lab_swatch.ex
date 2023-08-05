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

  wasm do
    ColorConversion.funcp()

    # import_funcp :math, powf32(x: F32, y: F32), F32

    func to_svg(), I32.String do
      build! do
        append!(:do_linear_gradient)
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
        append!(:do_linear_gradient_stop, [1.0, 1.0, 1.0, 1.0])
        append!(~S{</linearGradient>\n})
      end
    end
  end

  wasm F32 do
    funcp do_linear_gradient_stop(fraction: F32, r: F32, g: F32, b: F32), I32 do
      # percentage = "#{index / max * 100}%"

      build! do
        append!(~S{<stop offset="})
        append!(decimal_f32: fraction * 100.0)
        append!(~S{" stop-color="})
        append!(~S{rgba(})
        append!(decimal_f32: F32.nearest(r * 255.0))
        append!(~S{,})
        append!(decimal_f32: F32.nearest(g * 255.0))
        append!(~S{,})
        append!(decimal_f32: F32.nearest(b * 255.0))
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
