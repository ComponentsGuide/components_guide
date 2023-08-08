defmodule ComponentsGuide.Wasm.Examples.LabSwatch do
  use Orb
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  use BumpAllocator
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

  wasm_import(:log,
    i32: Orb.DSL.funcp(name: :log_i32, params: I32),
    f32: Orb.DSL.funcp(name: :log_f32, params: F32)
  )

  F32.export_global(:mutable, swatch_size: 160.0)
  F32.export_global(:mutable, quantization: 16.0)

  F32.export_global(:mutable,
    l: 88.0,
    a: 94.0,
    b: 60.0
  )

  F32.global(
    mouse_offset_x: 0.0,
    mouse_offset_y: 0.0
  )

  I32.enum([:component_l, :component_a, :component_b], 1)
  I32.export_global(:mutable, last_changed_component: 0)

  BumpAllocator.export_alloc()

  wasm F32 do
    ColorConversion.funcp()

    func l_changed(new_value: F32) do
      @last_changed_component = @component_l
    end

    func a_changed(new_value: F32) do
      @last_changed_component = @component_a
    end

    func b_changed(new_value: F32) do
      @last_changed_component = @component_b
    end

    funcp mouse_offset_changed(x: F32, y: F32), offset: F32 do
      offset = (x / @swatch_size + y / @swatch_size) / 2.0

      if I32.eq(@last_changed_component, @component_l) do
        @l = offset * 100.0
      end

      if I32.eq(@last_changed_component, @component_a) do
        @a = ((offset * 2.0 - 1.0) * 127.0) |> F32.nearest()
      end

      if I32.eq(@last_changed_component, @component_b) do
        @b = ((offset * 2.0 - 1.0) * 127.0) |> F32.nearest()
      end
    end

    func mousedown_offset(x: F32, y: F32) do
      call(:mouse_offset_changed, x, y)
    end

    func mousemove_offset(x: F32, y: F32) do
      call(:mouse_offset_changed, x, y)
    end

    # import_funcp :math, powf32(x: F32, y: F32), F32

    func to_html(), I32.String do
      build! do
        # content_tag! "div.flex" do
        # content_tag! :div, [{"class", "flex"}] do
        append!(~S{<div class="flex gap-4">\n})
        append!(:swatch_svg, @component_l)
        append!(:swatch_svg, @component_a)
        append!(:swatch_svg, @component_b)
        append!(~S{</div>\n})

        append!(:do_output_code)
      end
    end

    funcp do_output_code(), I32.String, r: F32, g: F32, b: F32 do
      build! do
        append!(~S{<output class="flex mt-4"><pre>\n})
        append!(~S{lab(})
        append!(decimal_f32: @l)
        append!(~S{% })
        append!(decimal_f32: @a)
        append!(~S{ })
        # append!(decimal_f32: @b)
        append!(decimal_f32: global_get(:b))
        append!(~S{)\n})

        # call(:lab_to_srgb, @l, @a, @b)
        call(:lab_to_srgb, global_get(:l), global_get(:a), global_get(:b))
        b = :pop
        g = :pop
        r = :pop
        append!(~S{rgb(})
        # append!(decimal_i32: I32.trunc_f32_u(F32.nearest(r * 255.0)))
        # append!(~S{ })
        # append!(decimal_i32: I32.trunc_f32_u(F32.nearest(g * 255.0)))
        # append!(~S{ })
        # append!(decimal_i32: I32.trunc_f32_u(F32.nearest(b * 255.0)))
        append!(decimal_f32: F32.nearest(r * 255.0))
        append!(~S{ })
        append!(decimal_f32: F32.nearest(g * 255.0))
        append!(~S{ })
        append!(decimal_f32: F32.nearest(b * 255.0))
        append!(~S{)\n})

        append!(~S{</pre></output>\n})
      end
    end

    func to_svg(), I32.String do
      build! do
        append!(:swatch_svg, @component_l)
      end
    end

    func swatch_svg(component_id: I32), I32.String do
      build! do
        append!(
          ~S(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width="160" height="160" data-action )
        )

        if I32.eq(component_id, @component_l), do: append!(~S{data-mousedown="l_changed" data-mousedown-mousemove="l_changed"})
        if I32.eq(component_id, @component_a), do: append!(~S{data-mousedown="a_changed" data-mousedown-mousemove="a_changed"})
        if I32.eq(component_id, @component_b), do: append!(~S{data-mousedown="b_changed" data-mousedown-mousemove="b_changed"})

        append!(~S(>\n))

        append!(~S(<defs>\n))
        append!(:do_linear_gradient, component_id)
        append!(~S(</defs>\n))

        append!(~S{<rect width="1" height="1" fill="url('#lab-})
        if I32.eq(component_id, @component_l), do: append!(~S{l})
        if I32.eq(component_id, @component_a), do: append!(~S{a})
        if I32.eq(component_id, @component_b), do: append!(~S{b})
        append!(~S{-gradient')" />\n})

        # append!(~S{<circle data-drag-knob cx="<%= l / 100.0 %>" cy="<%= l / 100.0 %>" r="0.05" fill="white" stroke="black" stroke-width="0.01" />})
        if I32.eq(component_id, @component_l), do: append!(:do_drag_knob, @l / 100.0)
        if I32.eq(component_id, @component_a), do: append!(:do_drag_knob, @a / 127.0 / 2.0 + 0.5)
        if I32.eq(component_id, @component_b), do: append!(:do_drag_knob, @b / 127.0 / 2.0 + 0.5)
        # append!(:do_drag_knob, 0.5)

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

        if I32.eq(component_id, @component_l), do: append!(~S{lab-l-gradient})
        if I32.eq(component_id, @component_a), do: append!(~S{lab-a-gradient})
        if I32.eq(component_id, @component_b), do: append!(~S{lab-b-gradient})

        append!(~S{" gradientTransform="scale(1.414) rotate(45)">\n})

        loop Stops do
          append!(:do_linear_gradient_stop_for, [
            i / @quantization,
            component_id
          ])

          i = i + 1.0
          Stops.continue(if: i <= @quantization)
        end

        append!(~S{</linearGradient>\n})
      end
    end
  end

  wasm F32 do
    funcp do_linear_gradient_stop_for(fraction: F32, component_id: I32), I32 do
      I32.match component_id do
        @component_l ->
          call(
            :do_linear_gradient_stop,
            fraction,
            call(:interpolate, fraction, 0.0, 100.0),
            @a,
            @b
          )

        @component_a ->
          call(
            :do_linear_gradient_stop,
            fraction,
            @l,
            call(:interpolate, fraction, -127.0, 127.0),
            @b
          )

        @component_b ->
          call(
            :do_linear_gradient_stop,
            fraction,
            @l,
            @a,
            call(:interpolate, fraction, -127.0, 127.0)
          )
      end
    end

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

      inline for var! <- [:blue, :green, :red] do
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

  # @wasm File.read!(Path.join(__DIR__, "lab_swatch.wasm"))

  def to_wasm() do
    File.read!(Path.join(__DIR__, "lab_swatch.wasm"))
  end

  def write_wat!() do
    wat_path = Path.join(__DIR__, "lab_swatch.wat")
    File.write!(wat_path, __MODULE__.to_wat())
    # System.cmd("wat2wasm", [wat_path])
  end
end
