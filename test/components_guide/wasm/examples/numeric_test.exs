defmodule ComponentsGuide.Wasm.Examples.NumericTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Numeric

  describe "UnitInterval" do
    alias Numeric.UnitInterval

    test "to_wat" do
      assert UnitInterval.to_wat() =~ "(f32.convert_i32_s"
      assert UnitInterval.to_wat() =~ "(param $value f32)"
      assert UnitInterval.to_wat() =~ "(result i32)"
    end

    test "validate definition", do: UnitInterval.validate_definition!()

    @tag :skip
    test "to_int_in_range" do
      assert Wasm.call(UnitInterval, :to_int_in_range, 0.0, 1, 10) == 1
    end
  end
end
