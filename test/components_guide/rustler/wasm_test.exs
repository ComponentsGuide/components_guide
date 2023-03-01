defmodule ComponentsGuide.Rustler.WasmTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Wasm

  test "add/2" do
    assert Wasm.add(3, 4) == 7
  end

  test "reverse_string/1" do
    assert Wasm.reverse_string("abcd") == "dcba"
  end

  test "wasm_list_exports/1 single func" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    assert Wasm.wasm_list_exports({:wat, wasm_source}) == [{:func, "answer"}]
  end

  test "wasm_list_exports/1 two funcs" do
    wasm_source = """
    (module $two_funcs
      (func (export "answer") (result i32)
       i32.const 42
      )
      (memory (export "mem") 1)
      (func (export "get_pi") (result f32)
       f32.const 3.14
      )
    )
    """

    assert Wasm.wasm_list_exports({:wat, wasm_source}) == [
             {:func, "answer"},
             {:memory, "mem"},
             {:func, "get_pi"}
           ]
  end

  test "wasm_example/2" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    assert Wasm.wasm_example(wasm_source, "answer") == 42
  end

  test "wasm_example/2 dsl" do
    # wasm_source = module([
    #   func(export("answer"), {:result, :i32}, {:i32_const, 42})
    # ])
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
    (module $add_func
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
    (module $multiply_func
      (func $multiply (param $a i32) (param $b i32) (result i32)
        local.get $a
        local.get $b
        i32.mul)
      (export "multiply" (func $multiply))
    )
    """

    assert Wasm.wasm_example(wasm_source, "multiply", 7, 5) == 35
  end

  test "wasm_example/3 checking a number is within a range" do
    wasm_source = """
    (module $range_func
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

  test "wasm_string/2 spits out string" do
    wasm_source = """
    (module $string_start_end
      (import "env" "buffer" (memory 1))
      (data (i32.const 256) "Know the length of this string")
      (func (export "main") (result i32 i32)
        (i32.const 256) (i32.const 30)
      )
    )
    """

    assert Wasm.wasm_example(wasm_source, "main") == {256, 30}
    assert Wasm.wasm_string(wasm_source, "main") == "Know the length of this string"
  end

  test "wasm_string/2 spits out null-terminated string" do
    wasm_source = """
    (module $string_null_terminated
      (import "env" "buffer" (memory 1))
      (data (i32.const 256) "No need to know the length of this string")
      (func (export "main") (result i32)
        (i32.const 256)
      )
    )
    """

    assert Wasm.wasm_example(wasm_source, "main") == 256
    assert Wasm.wasm_string(wasm_source, "main") == "No need to know the length of this string"
  end

  test "wasm_string/2 spits out HTML strings" do
    wasm_source = """
    (module $string_html
      (import "env" "buffer" (memory 1))
      (global $doctype (mut i32) (i32.const 65536))
      (data (i32.const 65536) "<!doctype html>")
      (func (export "main") (result i32 i32)
        (get_global $doctype) (i32.const 15)
      )
    )
    """

    assert Wasm.wasm_example(wasm_source, "main") == {65536, 15}
    assert Wasm.wasm_string(wasm_source, "main") == "<!doctype html>"
  end

  test "wasm_string/2 looks up HTTP status" do
    wasm_source = ~s"""
    (module $string_html
      (import "env" "buffer" (memory 1))
      (data (i32.const #{200*24}) "OK\\00")
      (data (i32.const #{201*24}) "Created\\00")
      (data (i32.const #{204*24}) "No Content\\00")
      (data (i32.const #{205*24}) "Reset Content\\00")
      (data (i32.const #{301*24}) "Moved Permanently\\00")
      (data (i32.const #{302*24}) "Found\\00")
      (data (i32.const #{303*24}) "See Other\\00")
      (data (i32.const #{304*24}) "Not Modified\\00")
      (data (i32.const #{307*24}) "Temporary Redirect\\00")
      (data (i32.const #{400*24}) "Bad Request\\00")
      (data (i32.const #{401*24}) "Unauthorized\\00")
      (data (i32.const #{403*24}) "Forbidden\\00")
      (data (i32.const #{404*24}) "Not Found\\00")
      (data (i32.const #{405*24}) "Method Not Allowed\\00")
      (data (i32.const #{409*24}) "Conflict\\00")
      (data (i32.const #{412*24}) "Precondition Failed\\00")
      (data (i32.const #{413*24}) "Payload Too Large\\00")
      (data (i32.const #{422*24}) "Unprocessable Entity\\00")
      (data (i32.const #{429*24}) "Too Many Requests\\00")
      (func (export "lookup") (param $status i32) (result i32)
        local.get $status
        i32.const 24
        i32.mul
      )
    )
    """

    assert Wasm.wasm_string(wasm_source, "lookup", 200) == "OK"
    assert Wasm.wasm_string(wasm_source, "lookup", 201) == "Created"
    assert Wasm.wasm_string(wasm_source, "lookup", 204) == "No Content"
    assert Wasm.wasm_string(wasm_source, "lookup", 205) == "Reset Content"
    assert Wasm.wasm_string(wasm_source, "lookup", 301) == "Moved Permanently"
    assert Wasm.wasm_string(wasm_source, "lookup", 302) == "Found"
    assert Wasm.wasm_string(wasm_source, "lookup", 303) == "See Other"
    assert Wasm.wasm_string(wasm_source, "lookup", 304) == "Not Modified"
    assert Wasm.wasm_string(wasm_source, "lookup", 307) == "Temporary Redirect"
    assert Wasm.wasm_string(wasm_source, "lookup", 401) == "Unauthorized"
    assert Wasm.wasm_string(wasm_source, "lookup", 403) == "Forbidden"
    assert Wasm.wasm_string(wasm_source, "lookup", 404) == "Not Found"
    assert Wasm.wasm_string(wasm_source, "lookup", 405) == "Method Not Allowed"
    assert Wasm.wasm_string(wasm_source, "lookup", 409) == "Conflict"
    assert Wasm.wasm_string(wasm_source, "lookup", 412) == "Precondition Failed"
    assert Wasm.wasm_string(wasm_source, "lookup", 413) == "Payload Too Large"
    assert Wasm.wasm_string(wasm_source, "lookup", 422) == "Unprocessable Entity"
    assert Wasm.wasm_string(wasm_source, "lookup", 429) == "Too Many Requests"
    assert Wasm.wasm_string(wasm_source, "lookup", 100) == ""
    # Crashes:
    # assert Wasm.wasm_string(wasm_source, "lookup", -1) == ""
  end

  # test "global calculates mean" do
  #   wasm_source = ~S"""
  #   (module $calculate_mean
  #     (import "env" "buffer" (memory 1))
  #     (global $count (mut i32) (i32.const 0))
  #     (global $tally (mut i32) (i32.const 0))
  #     (func (export "insert") (param $element i32)
  #       global.get $count
  #       i32.const 1
  #       global.set $count

  #       global.get $tally
  #       local.get $element
  #       global.set $tally
  #     )
  #     (func (export "calculate_mean") (result i32)
  #       global.get $tally
  #       global.get $count
  #       i32.div_u
  #     )
  #   )
  #   """

  #   instance = Wasm.create_instance(wasm_source)
  #   Wasm.call(instance, "insert", 1)
  #   Wasm.call(instance, "insert", 2)
  #   Wasm.call(instance, "insert", 3)
  #   assert Wasm.call_string(instance, "calculate_mean") == 2
  # end

  # defwasm multiply(a, b) do
  #   Wasm.func multiply(a, b) do
  #     W32.mul(a, b)
  #   end
  # end

  # defwasmmodule multiply do
  #   Wasm.func multiply(a, b) do
  #     W32.mul(a, b)
  #   end
  #   export(multiply)
  # end
end
