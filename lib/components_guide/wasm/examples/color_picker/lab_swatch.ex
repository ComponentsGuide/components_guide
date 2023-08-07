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

  F32.export_global(:mutable,
    l: 50.0,
    a: 100,
    b: -128
  )

  I32.enum([:component_l, :component_a, :component_b])

  wasm F32 do
    ColorConversion.funcp()

    # import_funcp :math, powf32(x: F32, y: F32), F32

    func to_html(), I32.String do
      build! do
        append!(:swatch_svg, @component_l)
      end
    end

    func to_svg(), I32.String do
      build! do
        append!(:swatch_svg, @component_l)
      end
    end

    func swatch_svg(swatch: I32), I32.String do
      build! do
        append!(
          ~S(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width="160" height="160" data-color-property="l">\n)
        )

        append!(~S(<defs>\n))
        append!(:do_linear_gradient, @component_l)
        append!(~S(</defs>\n))
        append!(~S{<rect width="1" height="1" fill="url('#lab-l-gradient')" />\n})

        # append!(~S{<circle data-drag-knob cx="<%= l / 100.0 %>" cy="<%= l / 100.0 %>" r="0.05" fill="white" stroke="black" stroke-width="0.01" />})
        append!(:do_drag_knob, 0.5)

        append!(~S{</svg>\n})
      end
    end

    funcp do_drag_knob(offset: F32), I32.String do
      build! do
        append!(~S{<circle data-drag-knob="" cx="})
        append!(decimal_f32: offset)
        append!(~S{" cy="})
        append!(decimal_f32: offset)
        append!(~S{" r="0.05" fill="white" stroke="black" stroke-width="0.01" />\n})
      end
    end

    funcp interpolate(t: F32, lowest: F32, highest: F32), F32 do
      (highest - lowest) * t + lowest
    end

    funcp do_linear_gradient(component_id: I32), I32.String, i: F32 do
      build! do
        append!(~S{<linearGradient id="})

        if I32.eq(component_id, @component_l) do
          append!(~S{lab-l-gradient})
        end

        append!(~S{" gradientTransform="scale(1.414) rotate(45)">\n})

        loop Stops do
          append!(:do_linear_gradient_stop, [
            i / 4.0,
            call(:interpolate, i / 4.0, 0.0, 100.0),
            @a,
            @b
          ])

          i = i + 1.0
          Stops.continue(if: i <= 4.0)
        end

        # append!(:do_linear_gradient_stop, [0.0, 0.0, 0.0, 0.0])
        # append!(:do_linear_gradient_stop, [0.25, 25.0, 0.0, 0.0])
        # append!(:do_linear_gradient_stop, [0.5, 50.0, 0.0, 0.0])
        # append!(:do_linear_gradient_stop, [0.75, 75.0, 0.0, 0.0])
        # append!(:do_linear_gradient_stop, [1.0, 100.0, 0.0, 0.0])
        append!(~S{</linearGradient>\n})
      end
    end
  end

  wasm F32 do
    funcp do_linear_gradient_stop(fraction: F32, l: F32, a: F32, b: F32), I32 do
      build! do
        append!(~S{<stop offset="})
        append!(decimal_f32: fraction * 100.0)
        append!(~S{%" stop-color="})
        append!(:do_css_color_lab_srgb, l, a, b)
        append!(~S{" />\n})
      end
    end

    funcp do_css_color_lab_srgb(l: F32, a: F32, b: F32), I32.String,
      red: F32,
      green: F32,
      blue: F32 do
      call(:lab_to_srgb, l, a, b)

      inline for var! <- [:red, :green, :blue] do
        F32.nearest(:pop * 255.0) |> F32.min(255.0) |> F32.max(0.0)
        local_set(var!)
      end

      build! do
        append!(~S{rgba(})
        append!(decimal_f32: red)
        append!(~S{,})
        append!(decimal_f32: green)
        append!(~S{,})
        append!(decimal_f32: blue)
        append!(~S{,1)})
      end
    end
  end

  @wasm File.read!(Path.join(__DIR__, "lab_swatch.wasm"))

  def to_wasm() do
    @wasm
  end
end
