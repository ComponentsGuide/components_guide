defmodule ComponentsGuide.Rustler.WasmBuilderTest do
  use ExUnit.Case, async: true

  import ComponentsGuide.Rustler.WasmBuilder

  test "to_wat/1 single func" do
    wasm =
      module("single_func") do
        func(export("answer"), result(:i32), [
          42
        ])
      end

    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
        i32.const 42
      )
    )
    """

    assert to_wat(wasm) == wasm_source
  end

  test "to_wat/1 two funcs" do
    wasm =
      module("two_funcs", [
        memory(export("mem"), 1),
        func(export("answer"), result(:i32), [
          42
        ]),
        func(export("get_pi"), result(:f32), [
          3.14
        ])
      ])

    wasm_source = """
    (module $two_funcs
      (memory (export "mem") 1)
      (func (export "answer") (result i32)
        i32.const 42
      )
      (func (export "get_pi") (result f32)
        f32.const 3.14
      )
    )
    """

    assert to_wat(wasm) == wasm_source
  end

  test "to_wat/1 many data" do
    wasm =
      module("string_html", [
        wasm_import("env", "buffer", memory(1)),
        data(200 * 24, "OK\\00"),
        func(export("lookup"), param("status", :i32), result(:i32), [
          local_get("status"),
          24,
          :i32_mul
        ])
      ])

    wasm_source = ~s"""
    (module $string_html
      (import "env" "buffer" (memory 1))
      (data (i32.const #{200 * 24}) "OK\\00")
      (func (export "lookup") (param $status i32) (result i32)
        local.get $status
        i32.const 24
        i32.mul
      )
    )
    """

    assert to_wat(wasm) == wasm_source
  end

  # defwasm multiply(a, b) do
  #   Build.func multiply(a, b) do
  #     W32.mul(a, b)
  #   end
  # end

  # defwasmmodule multiply do
  #   Build.func multiply(a, b) do
  #     W32.mul(a, b)
  #   end
  #   export(multiply)
  # end
end
