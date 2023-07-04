defmodule ComponentsGuide.Wasm.Examples.Format.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Format

  describe "IntToString" do
    alias Format.IntToString

    test "u32toa_count" do
      Instance.run(IntToString)

      assert Wasm.call(IntToString, :u32toa_count, 0) == 1
      assert Wasm.call(IntToString, :u32toa_count, 7) == 1
      assert Wasm.call(IntToString, :u32toa_count, 17) == 2
      assert Wasm.call(IntToString, :u32toa_count, 173) == 3
      assert Wasm.call(IntToString, :u32toa_count, 604_800) == 6
    end
  end
end
