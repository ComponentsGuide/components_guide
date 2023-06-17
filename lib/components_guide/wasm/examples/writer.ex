defmodule ComponentsGuide.Wasm.Examples.Writer do
  use ComponentsGuide.Wasm
  import ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  import ComponentsGuide.Wasm.Examples.Memory.Copying
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  def write!(src, byte_count) do
    snippet writer: I32 do
      memcpy(writer, src, byte_count)
      writer = I32.add(writer, byte_count)
    end
  end

  def write!({:i32_const_string, strptr, string}) do
    byte_count = byte_size(string)

    snippet writer: I32 do
      memcpy(writer, strptr, byte_count)
      writer = I32.add(writer, byte_count)
    end
  end

  def write!(ascii: char) do
    snippet writer: I32 do
      memory32_8![writer] = char
      writer = I32.add(writer, 1)
    end
  end

  def write!(u32: int) do
    snippet writer: I32 do
      writer = IntToString.write_u32(int, writer)
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
