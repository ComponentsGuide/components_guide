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

  def write!(list) when is_list(list) do
    snippet writer: I32 do
      writer = global_get(:bump_offset)

      inline for item! <- list do
        case item! do
          {:i32_const_string, strptr, string} ->
            [
              memcpy(global_get(:bump_offset), strptr, byte_size(string)),
              I32.add(global_get(:bump_offset), byte_size(string)),
              global_set(:bump_offset)
            ]

          strptr ->
            [
              memcpy(global_get(:bump_offset), strptr, call(:strlen, strptr)),
              I32.add(global_get(:bump_offset), call(:strlen, strptr)),
              global_set(:bump_offset)
            ]
        end
      end

      writer
    end
  end
end
