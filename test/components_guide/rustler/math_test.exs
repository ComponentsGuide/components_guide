defmodule ComponentsGuide.Rustler.MathTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Math

  test "add/2" do
    assert Math.add(3, 4) == 7
  end

  test "reverse_string/1" do
    assert Math.reverse_string("abcd") == "dcba"
  end

  test "wasm_example/2" do
    wasm_source = """
    (module
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    assert Math.wasm_example(wasm_source, "answer") == 42
  end
end
