defmodule ComponentsGuide.Wasm.Examples.StringBuilder do
  use Orb
  alias ComponentsGuide.Wasm.Examples.Memory.Copying
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  use Copying

  defmacro __using__(_) do
    quote do
      use Copying
      use I32.String
      use IntToString

      import unquote(__MODULE__)

      # global do
      #   @bump_write_level 0
      # end

      I32.global(bump_write_level: 0)

      Orb.wasm do
        unquote(__MODULE__).funcp()
      end
    end
  end

  wasm U32 do
    funcp bump_write_start() do
      if I32.eqz(@bump_write_level) do
        @bump_mark = @bump_offset
      end

      @bump_write_level = @bump_write_level + 1
    end

    funcp bump_write_done(), I32 do
      assert!(@bump_write_level > 0)
      @bump_write_level = @bump_write_level - 1

      if I32.eqz(@bump_write_level) do
        # I32.store8(@bump_offset, 0x0)
        # Memory.store!(I32.U8, @bump_offset, 0x0)
        {:i32, :store8, @bump_offset, 0x0}
        @bump_offset = I32.add(@bump_offset, 1)
      end

      @bump_mark
    end

    funcp bump_write_str(str_ptr: I32.U8.UnsafePointer), len: I32 do
      return(if: I32.eq(str_ptr, @bump_mark))

      len = call(:strlen, str_ptr)
      Copying.memcpy(@bump_offset, str_ptr, len)
      @bump_offset = @bump_offset + len
    end

    funcp bump_written?(), I32 do
      @bump_offset > @bump_mark
    end
  end

  def build_begin!(), do: Orb.DSL.call(:bump_write_start)
  def build_done!(), do: Orb.DSL.call(:bump_write_done)
  def appended?(), do: Orb.DSL.call(:bump_written?)

  defmacro build!(do: block) do
    items =
      case block do
        {:__block__, _, items} -> items
        term -> List.wrap(term)
      end

    items =
      for item <- items do
        case item do
          {:data_for_constant, _meta, _args} = node ->
            # quote(bind_quoted: [node: node], do: append!(node))
            # quote(do: append!(node))
            {:append!, [], [node]}

          other ->
            other
        end
      end

    quote do
      [
        build_begin!(),
        unquote(items),
        build_done!()
      ]
    end
  end

  # For nested build functions.
  # We want inner functions to also return strings for easier debugging of their result, not just append.
  def append!(function, a, b, c) when is_atom(function) do
    import Orb.DSL

    call(function, a, b, c) |> drop()
  end

  def append!(function, a, b) when is_atom(function) do
    import Orb.DSL

    call(function, a, b) |> drop()
  end

  def append!(function, args) when is_atom(function) and is_list(args) do
    import Orb.DSL

    typed_call(:i32, function, args) |> drop()
  end

  def append!(function, a) when is_atom(function) do
    import Orb.DSL

    call(function, a) |> drop()
  end

  def append!(function) when is_atom(function) do
    import Orb.DSL

    call(function) |> drop()
  end

  def append!({:i32_const_string, _offset, _string} = str_ptr) do
    Orb.DSL.call(:bump_write_str, str_ptr)
  end

  def append!(string: str_ptr) do
    Orb.DSL.call(:bump_write_str, str_ptr)
  end

  def append!(u8: char) do
    snippet U32 do
      # Memory.store!(I32.U8, @bump_offset, char)
      {:i32, :store8, @bump_offset, char}
      @bump_offset = @bump_offset + 1
    end
  end

  def append!(ascii: char), do: append!(u8: char)

  def append!(decimal_u32: int) do
    snippet do
      @bump_offset = IntToString.write_u32(int, @bump_offset)
    end
  end

  def append!(decimal_f32: f) do
    # snippet U32 do
    #   # call(:format_f32, f, @bump_offset) |> I32.add(@bump_offset)
    #   call(:format_f32, f, {:global_get, :bump_offset}) |> I32.add({:global_get, :bump_offset})
    #   {:global_set, :bump_offset}
    # end
    [
      # call(:format_f32, f, @bump_offset) |> I32.add(@bump_offset)
      Orb.DSL.call(:format_f32, f, {:global_get, :bump_offset}) |> Orb.I32.add({:global_get, :bump_offset}),
      {:global_set, :bump_offset}
    ]
  end

  def append!(hex_upper: hex) do
    # This might be a bit over the top…
    {initial, following} =
      case hex do
        [_value, {:local_tee, identifier}] ->
          {hex, {:local_get, identifier}}

        _ ->
          {hex, hex}
      end

    snippet U32 do
      # push(hex)
      #
      # push(I32.le_u(hex, 9))
      #
      # :drop
      #
      # :pop

      # memory32_8![@bump_offset] = I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))

      # I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))

      # push(@bump_offset)
      # push(@bump_offset)

      # memory32_8![0x0] = hex
      # if I32.le_u(memory32_8![0x0].unsigned, 9) do
      #   memory32_8![@bump_offset] = I32.add(memory32_8![0x0].unsigned, ?0)
      # else
      #   memory32_8![@bump_offset] = I32.sub(memory32_8![0x0].unsigned, 10) |> I32.add(?A)
      # end

      # I32.when? I32.le_u(:pop, 9) do
      #   push(hex)
      #   I32.add(:pop, ?0)
      # else
      #   push(hex)
      #   I32.sub(:pop, 10) |> I32.add(?A)
      # end
      # memory32_8![:pop] = :pop

      # memory32_8![@bump_offset] =
      #   initial |> I32.add(I32.when?(I32.le_u(following, 9), do: ?0, else: inline(do: ?A - 10)))

      # I32.store8(@bump_offset, initial + I32.when?(following <= 9, do: ?0, else: ?A - 10))
      {:i32, :store8, @bump_offset, initial + I32.when?(following <= 9, do: ?0, else: ?A - 10)}

      # memory32_8![@bump_offset] =
      #   I32.when?(I32.le_u(initial, 9), do: I32.add(following, ?0), else: I32.sub(following, 10) |> I32.add(?A))

      # FIXME: we are evaluating hex multiple times. Do we have to stash it in a variable?
      # memory32_8![@bump_offset] =
      #   I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))

      @bump_offset = @bump_offset + 1
    end
  end

  def append!(list) when is_list(list) do
    for item <- list do
      append!([item])
    end
  end

  #     def append!(list) when is_list(list) do
  #       snippet do
  #         inline for item <- list do
  #           # WE NEED TO INCREMENT bump_offset after each round
  #           case item do
  #             {:ascii, char} ->
  #               snippet do
  #                 memory32_8![@bump_offset] = char
  #               end
  #
  #             {:hex_upper, hex} ->
  #               snippet do
  #                 memory32_8![@bump_offset] =
  #                   I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))
  #               end
  #           end
  #         end
  #
  #         @bump_offset = I32.add(@bump_offset, length(list))
  #       end |> dbg()
  #     end

  def join!(list!) when is_list(list!) do
    alias ComponentsGuide.Wasm.Examples.Memory.Copying

    snippet do
      build_begin!()

      inline for item! <- ^list! do
        case item! do
          {:i32_const_string, strptr, string} ->
            [
              Copying.memcpy(global_get(:bump_offset), strptr, byte_size(string)),
              I32.add(global_get(:bump_offset), byte_size(string)),
              global_set(:bump_offset)
            ]

          str_ptr ->
            call(:bump_write_str, str_ptr)
        end
      end

      build_done!()
    end
  end

  #   defmacro sigil_s({:<<>>, line, pieces}, []) do
  #     dbg(pieces)
  #
  #     pieces =
  #       for piece <- pieces do
  #         piece
  #       end
  #
  #     # {:<<>>, line, pieces}
  #     # dbg({line, pieces})
  #     quote do
  #       write!(unquote(pieces))
  #     end
  #   end
end
