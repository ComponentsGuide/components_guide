defmodule ComponentsGuide.Wasm.Examples.Format.Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Wasm
  alias ComponentsGuide.Wasm.Examples.Format

  describe "IntToString" do
    alias Format.IntToString

    test "format_u32_char_count" do
      assert Wasm.call(IntToString, :format_u32_char_count, 0) == 1
      assert Wasm.call(IntToString, :format_u32_char_count, 7) == 1
      assert Wasm.call(IntToString, :format_u32_char_count, 17) == 2
      assert Wasm.call(IntToString, :format_u32_char_count, 173) == 3
      assert Wasm.call(IntToString, :format_u32_char_count, 604_800) == 6
    end
  end
end
