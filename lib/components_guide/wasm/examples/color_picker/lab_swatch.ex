defmodule ComponentsGuide.Wasm.Examples.LabSwatch do
  use Orb
  use SilverOrb.BumpAllocator
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

  defmodule Math do
    use Orb.Import

    defw(powf32(a: F32, b: F32), F32)
  end

  wasm_import(:format,
    f32: Orb.DSL.funcp(name: :format_f32, params: {F32, I32}, result: I32)
  )

  wasm_import(:log,
    i32: Orb.DSL.funcp(name: :log_i32, params: I32),
    f32: Orb.DSL.funcp(name: :log_f32, params: F32)
  )

  F32.export_global(:mutable, swatch_size: 120.0)
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

  SilverOrb.BumpAllocator.export_alloc()

  wasm_mode(F32)

  # defw l_changed(new_value: F32) do
  #   @last_changed_component = @component_l
  # end

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

    funcp pointer_offset_changed(x: F32, y: F32), offset: F32 do
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
    |> export("pointerdown_offset")
    |> export("pointermove_offset")

    # import_funcp :math, powf32(x: F32, y: F32), F32
  end

  defw to_html(), I32.String do
    build! do
      # content_tag! "div.flex" do
      # content_tag! :div, [{"class", "flex"}] do
      ~S{<div class="flex gap-4">\n}
      swatch_svg(@component_l)
      swatch_svg(@component_a)
      swatch_svg(@component_b)
      ~S{</div>\n}

      do_output_code()
    end
  end

  defwp do_output_code(), I32.String do
    build! do
      ~S{<output class="flex flex-col mt-4 font-mono">\n}

      ~S{<p class="flex items-center gap-1">}
      ~S{<svg viewBox="0 0 1 1" width="1rem" height="1rem"><rect width="1" height="1" fill="}
      do_css_lab()
      ~S{" /></svg> }
      do_css_lab()
      ~S{</p>\n}

      ~S{<p class="flex items-center gap-1">}
      ~S{<svg viewBox="0 0 1 1" width="1rem" height="1rem"><rect width="1" height="1" fill="}
      do_css_rgb()
      ~S{" /></svg> }
      do_css_rgb()
      ~S{</p>\n}

      ~S{</output>\n}
    end
  end

  defwp do_css_lab(), I32.String, r: F32, g: F32, b: F32 do
    build! do
      ~S{lab(}
      @l
      ~S{% }
      @a
      ~S{ }
      # append!(decimal_f32: @b)
      append!(decimal_f32: global_get(:b))
      ~S{)}
    end
  end

  defwp do_css_rgb(), I32.String, r: F32, g: F32, b: F32 do
    build! do
      typed_call({F32, F32, F32}, :lab_to_srgb, [@l, @a, global_get(:b)])
      b = Orb.Stack.pop(F32)
      g = Orb.Stack.pop(F32)
      r = Orb.Stack.pop(F32)

      ~S{rgb(}
      # append!(decimal_i32: I32.trunc_f32_u(F32.nearest(r * 255.0)))
      # ~S{ }
      # append!(decimal_i32: I32.trunc_f32_u(F32.nearest(g * 255.0)))
      # ~S{ }
      # append!(decimal_i32: I32.trunc_f32_u(F32.nearest(b * 255.0)))
      F32.nearest(r * 255.0)
      ~S{ }
      F32.nearest(g * 255.0)
      ~S{ }
      F32.nearest(b * 255.0)
      ~S{)}
    end
  end

  defw to_svg(), I32.String do
    swatch_svg(@component_l)
  end

  defwp swatch_svg(component_id: I32), I32.String do
    build! do
      ~S(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width=")
      @swatch_size
      ~S(" height=")
      @swatch_size
      ~S(" class="touch-none" data-action )

      if I32.eq(component_id, @component_l),
        do: ~S{data-pointerdown="l_changed" data-pointerdown+pointermove="l_changed"}

      if I32.eq(component_id, @component_a),
        do: ~S{data-pointerdown="a_changed" data-pointerdown+pointermove="a_changed"}

      if I32.eq(component_id, @component_b),
        do: ~S{data-pointerdown="b_changed" data-pointerdown+pointermove="b_changed"}

      ~S(>\n)

      ~S(<defs>\n)
      do_linear_gradient(component_id)
      ~S(</defs>\n)
      # const(Enum.join(["</defs>", "\n"]))
      # const(Enum.join(~HTML</defs>, "\n"]))

      ~S{<rect width="1" height="1" fill="url('#lab-}
      if I32.eq(component_id, @component_l), do: ~S(l)
      if I32.eq(component_id, @component_a), do: ~S(a)
      if I32.eq(component_id, @component_b), do: ~S(b)
      ~S{-gradient')" />\n}

      # append!(~S{<circle data-drag-knob cx="<%= l / 100.0 %>" cy="<%= l / 100.0 %>" r="0.05" fill="white" stroke="black" stroke-width="0.01" />})
      if I32.eq(component_id, @component_l), do: do_drag_knob(@l / 100.0)
      if I32.eq(component_id, @component_a), do: do_drag_knob(@a / 127.0 / 2.0 + 0.5)
      if I32.eq(component_id, @component_b), do: do_drag_knob(@b / 127.0 / 2.0 + 0.5)
      # append!(:do_drag_knob, 0.5)

      ~S{</svg>\n}
    end
  end

  defwp do_drag_knob(offset: F32) do
    # ~E(<circle data-drag-knob="" cx="<%= offset %>" cy="<%= offset %>" r="0.05" fill="white" stroke="black" stroke-width="0.01" />\n)

    _ =
      build! do
        ~S{<circle data-drag-knob="" cx="}
        offset
        ~S{" cy="}
        offset
        ~S{" r="0.05" fill="white" stroke="black" stroke-width="0.01" />\n}
      end
  end

  defwp interpolate(t: F32, lowest: F32, highest: F32), F32 do
    (highest - lowest) * t + lowest
  end

  defwp do_linear_gradient(component_id: I32), I32.String, i: F32 do
    build! do
      ~S{<linearGradient id="}

      if I32.eq(component_id, @component_l), do: ~S{lab-l-gradient}
      if I32.eq(component_id, @component_a), do: ~S{lab-a-gradient}
      if I32.eq(component_id, @component_b), do: ~S{lab-b-gradient}

      ~S{" gradientTransform="scale(1.414) rotate(45)">\n}

      loop Stops do
        _ = do_linear_gradient_stop_for(i / @quantization, component_id)

        i = i + 1.0
        Stops.continue(if: i <= @quantization)
      end

      ~S{</linearGradient>\n}
    end
  end

  defwp do_linear_gradient_stop_for(fraction: F32, component_id: I32), I32 do
    I32.match component_id do
      @component_l ->
        do_linear_gradient_stop(
          fraction,
          interpolate(fraction, 0.0, 100.0),
          @a,
          @b
        )

      @component_a ->
        do_linear_gradient_stop(
          fraction,
          @l,
          interpolate(fraction, -127.0, 127.0),
          @b
        )

      @component_b ->
        do_linear_gradient_stop(
          fraction,
          @l,
          @a,
          interpolate(fraction, -127.0, 127.0)
        )
    end
  end

  defwp do_linear_gradient_stop(fraction: F32, l: F32, a: F32, b: F32), I32 do
    build! do
      ~S{<stop offset="}
      fraction * 100.0
      ~S{%" stop-color="}
      do_css_color_lab_srgb(l, a, b)
      ~S{" />\n}
    end
  end

  defwp do_css_color_lab_srgb(l: F32, a: F32, b: F32), I32.String,
    red: F32,
    green: F32,
    blue: F32 do
    typed_call({F32, F32, F32}, :lab_to_srgb, [l, a, b])

    inline for var! <- [mut!(blue), mut!(green), mut!(red)] do
      wasm F32 do
        F32.nearest(Orb.Stack.pop(I32) * 255.0) |> F32.min(255.0) |> F32.max(0.0)
        var!.write
      end
    end

    build! do
      ~S{rgba(}
      red
      ~S{,}
      green
      ~S{,}
      blue
      ~S{,1)}
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
