defmodule ComponentsGuide.Wasm.Examples.NumericTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm

  describe "UnitInterval" do
    alias ComponentsGuide.Wasm.Examples.Numeric.UnitInterval

    test "to_wat" do
      assert UnitInterval.to_wat =~ "(f32.convert_i32_s"
    end

    @tag :skip
    test "to_int_in_range" do
      assert Wasm.call(UnitInterval, :to_int_in_range, 0.0, 1, 10) == 1
    end
  end
end
