defmodule ComponentsGuide.Rustler.WasmBuilderTest do
  use ExUnit.Case, async: true

  use ComponentsGuide.Rustler.WasmBuilder

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

  test "to_wat/1 defwasmmodule single func" do
    wasm =
      defwasmmodule single_func do
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

  # defwasmmodule TwoFuncs do

  # end

  test "to_wat/1 defwasmmodule two funcs" do
    wasm =
      defwasmmodule two_funcs do
        memory(export("mem"), 1)

        # defwasmfunc answer, result: i32 do
        #   42
        # end
        func(export("answer"), result(:i32), [
          42
        ])

        func(export("get_pi"), result(:f32), [
          3.14
        ])
      end

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
    statuses = [
      {200, "OK"},
      {201, "Created"},
      {204, "No Content"},
      {205, "Reset Content"},
      {301, "Moved Permanently"},
      {302, "Found"},
      {303, "See Other"},
      {304, "Not Modified"},
      {307, "Temporary Redirect"},
      {400, "Bad Request"},
      {401, "Unauthorized"},
      {403, "Forbidden"},
      {404, "Not Found"},
      {405, "Method Not Allowed"},
      {409, "Conflict"},
      {412, "Precondition Failed"},
      {413, "Payload Too Large"},
      {422, "Unprocessable Entity"},
      {429, "Too Many Requests"}
    ]

    wasm =
      module("string_html", [
        wasm_import("env", "buffer", memory(1)),
        for {status, message} <- statuses do
          data(status * 24, "#{message}\\00")
        end,
        func(export("lookup"), param("status", :i32), result(:i32), [
          # quote(do: status * 24),
          local_get("status"),
          24,
          i32(:mul)
        ])
      ])

    wasm_source = ~s"""
    (module $string_html
      (import "env" "buffer" (memory 1))
      (data (i32.const #{200 * 24}) "OK\\00")
      (data (i32.const #{201 * 24}) "Created\\00")
      (data (i32.const #{204 * 24}) "No Content\\00")
      (data (i32.const #{205 * 24}) "Reset Content\\00")
      (data (i32.const #{301 * 24}) "Moved Permanently\\00")
      (data (i32.const #{302 * 24}) "Found\\00")
      (data (i32.const #{303 * 24}) "See Other\\00")
      (data (i32.const #{304 * 24}) "Not Modified\\00")
      (data (i32.const #{307 * 24}) "Temporary Redirect\\00")
      (data (i32.const #{400 * 24}) "Bad Request\\00")
      (data (i32.const #{401 * 24}) "Unauthorized\\00")
      (data (i32.const #{403 * 24}) "Forbidden\\00")
      (data (i32.const #{404 * 24}) "Not Found\\00")
      (data (i32.const #{405 * 24}) "Method Not Allowed\\00")
      (data (i32.const #{409 * 24}) "Conflict\\00")
      (data (i32.const #{412 * 24}) "Precondition Failed\\00")
      (data (i32.const #{413 * 24}) "Payload Too Large\\00")
      (data (i32.const #{422 * 24}) "Unprocessable Entity\\00")
      (data (i32.const #{429 * 24}) "Too Many Requests\\00")
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
