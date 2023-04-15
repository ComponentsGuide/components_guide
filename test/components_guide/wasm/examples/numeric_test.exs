defmodule ComponentsGuide.Wasm.Examples.NumericTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Numeric

  describe "BasicMath" do
    alias Numeric.BasicMath

    # test "validate definition", do: BasicMath.validate_definition!()

    test "i32_double" do
      assert Wasm.call(BasicMath, :i32_double, 7) == 14
    end

    test "f32_double" do
      assert Wasm.call(BasicMath, :f32_double, 7.0) == 14.0
    end
  end

  describe "UnitInterval" do
    alias Numeric.UnitInterval

    test "to_wat" do
      assert UnitInterval.to_wat() =~ "(f32.convert_i32_s"
      assert UnitInterval.to_wat() =~ "(param $value f32)"
      assert UnitInterval.to_wat() =~ "(result i32)"
    end

    # test "validate definition", do: UnitInterval.validate_definition!()

    test "to_int_in_range" do
      # to_int_in_range = &Wasm.call(UnitInterval, :to_int_in_range, &1, &2, &3)
      to_int_in_range = Wasm.capture(UnitInterval, :to_int_in_range, 3)

      assert to_int_in_range.(0.0, 1, 10) == 1
      assert to_int_in_range.(0.0, 1, 10) == 1
      assert to_int_in_range.(0.05, 1, 10) == 1
      assert to_int_in_range.(0.099, 1, 10) == 1
      assert to_int_in_range.(0.11, 1, 10) == 2
      assert to_int_in_range.(0.499, 1, 10) == 5
      assert to_int_in_range.(0.51, 1, 10) == 6
      assert to_int_in_range.(0.999, 1, 10) == 10
    end
  end
end
