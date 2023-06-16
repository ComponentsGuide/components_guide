defmodule ComponentsGuide.Wasm.Examples.Writer do
  use ComponentsGuide.Wasm
  import ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.MemEql
  alias ComponentsGuide.Wasm.Examples.Memory.StringHelpers
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  def write!(src, byte_count) do
    snippet writer: I32 do
      memcpy(writer, src, byte_count)
      writer = I32.add(writer, byte_count)
    end
  end

  def write!({:i32_const_string, src_ptr, string}) do
    byte_count = byte_size(string)

    snippet writer: I32 do
      memcpy(writer, src_ptr, byte_count)
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
end
