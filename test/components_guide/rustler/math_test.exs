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

    assert Math.wasm_example(wasm_source, "answer") == 42
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

    assert Math.wasm_example(wasm_source, "add", 7, 5) == 12
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

    assert Math.wasm_example(wasm_source, "multiply", 7, 5) == 35
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

    assert Math.wasm_example(wasm_source, "validate", -1) == 0
    assert Math.wasm_example(wasm_source, "validate", 0) == 0
    assert Math.wasm_example(wasm_source, "validate", 1) == 1
    assert Math.wasm_example(wasm_source, "validate", 2) == 1
    assert Math.wasm_example(wasm_source, "validate", 10) == 1
    assert Math.wasm_example(wasm_source, "validate", 13) == 1
    assert Math.wasm_example(wasm_source, "validate", 255) == 1
    assert Math.wasm_example(wasm_source, "validate", 256) == 0
    assert Math.wasm_example(wasm_source, "validate", 257) == 0
    assert Math.wasm_example(wasm_source, "validate", 2000) == 0
  end
  
  # defwasm multiply(a, b) do
  #   Wasm.func multiply(a, b) do
  #     W32.mul(a, b)
  #   end
  # end
end
