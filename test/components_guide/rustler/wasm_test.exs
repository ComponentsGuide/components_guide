defmodule ComponentsGuide.Rustler.WasmTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Wasm

  test "add/2" do
    assert Wasm.add(3, 4) == 7
  end

  test "reverse_string/1" do
    assert Wasm.reverse_string("abcd") == "dcba"
  end

  test "wasm_example/2" do
    wasm_source = """
    (module
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    assert Wasm.wasm_example(wasm_source, "answer") == 42
  end

  test "wasm_example/2 dsl" do
    # wasm_source = module(func(export("answer"), :result_i32, {:i32_const, 42}))
    # wasm_source = module(func(export("answer"), Result.i32, {I32.const, 42}))
    # wasm_source = module({:func, {:export, "answer"}, {:result, :i32}, {:i32_const, 42}})

    wasm_source = """
    (module
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    assert Wasm.wasm_example(wasm_source, "answer") == 42
  end

  test "wasm_example/4 adding two numbers" do
    wasm_source = """
    (module
      (func $add (param $a i32) (param $b i32) (result i32)
        local.get $a
        local.get $b
        i32.add)
      (export "add" (func $add))
    )
    """

    assert Wasm.wasm_example(wasm_source, "add", 7, 5) == 12
  end

  test "wasm_example/4 multiplying two numbers" do
    wasm_source = """
    (module
      (func $multiply (param $a i32) (param $b i32) (result i32)
        local.get $a
        local.get $b
        i32.mul)
      (export "multiply" (func $multiply))
    )
    """

    assert Wasm.wasm_example(wasm_source, "multiply", 7, 5) == 35
  end

  test "wasm_example/4 checking a number is within a range" do
    wasm_source = """
    (module
      (func $validate (param $num i32) (result i32)
        (local $lt i32)
        (local $gt i32)
        (i32.lt_s (local.get $num) (i32.const 1))
        local.set $lt
        (i32.gt_s (local.get $num) (i32.const 255))
        local.set $gt
        (i32.or (local.get $lt) (local.get $gt))
        i32.eqz
      )
      (export "validate" (func $validate))
    )
    """

    assert Wasm.wasm_example(wasm_source, "validate", -1) == 0
    assert Wasm.wasm_example(wasm_source, "validate", 0) == 0
    assert Wasm.wasm_example(wasm_source, "validate", 1) == 1
    assert Wasm.wasm_example(wasm_source, "validate", 2) == 1
    assert Wasm.wasm_example(wasm_source, "validate", 10) == 1
    assert Wasm.wasm_example(wasm_source, "validate", 13) == 1
    assert Wasm.wasm_example(wasm_source, "validate", 255) == 1
    assert Wasm.wasm_example(wasm_source, "validate", 256) == 0
    assert Wasm.wasm_example(wasm_source, "validate", 257) == 0
    assert Wasm.wasm_example(wasm_source, "validate", 2000) == 0
  end

  test "wasm_example/4 spits out HTML strings" do
    wasm_source = """
    (module
      (import "env" "buffer" (memory 1))
      (data (i32.const 256) "Know the length of this string")
      (func (export "main") (param $num i32) (param $unused i32) (result i32 i32)
        (i32.const 256) (i32.const 30)
      )
    )
    """

    assert Wasm.wasm_example(wasm_source, "main", 0, 0) == {256, 30}
    assert Wasm.wasm_string(wasm_source, "main", 0, 0) == "Know the length of this string"
  end

  # defwasm multiply(a, b) do
  #   Wasm.func multiply(a, b) do
  #     W32.mul(a, b)
  #   end
  # end
end
