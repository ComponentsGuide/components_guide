defmodule ComponentsGuide.Wasm.Examples.Writer do
  use ComponentsGuide.Wasm
  import ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  import ComponentsGuide.Wasm.Examples.Memory.Copying
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  def write!(src, byte_count) do
    snippet U32, writer: I32.U8.Pointer do
      memcpy(writer, src, byte_count)
      writer = writer + byte_count
    end
  end

  def write!({:i32_const_string, strptr, string}) do
    byte_count = byte_size(string)

    snippet U32, writer: I32.U8.Pointer do
      memcpy(writer, strptr, byte_count)
      writer = writer + byte_count
    end
  end

  def write!(ascii: char) do
    snippet U32, writer: I32.U8.Pointer do
      writer[at!: 0] = char
      writer = writer + 1
    end
  end

  def write!(u32: int) do
    snippet nil, writer: I32.U8.Pointer do
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
