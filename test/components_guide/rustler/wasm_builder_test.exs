defmodule ComponentsGuide.Rustler.WasmBuilderTest do
  use ExUnit.Case, async: true

  use ComponentsGuide.Rustler.WasmBuilder
  alias ComponentsGuide.Rustler.WasmBuilder

  test "func" do
    wasm =
      func answer, result: :i32 do
        42
      end

    wasm_source = """
    (func (export "answer") (result i32)
      i32.const 42
    )\
    """

    assert to_wat(wasm) == wasm_source
  end

  defmodule SingleFunc do
    use ComponentsGuide.Rustler.WasmBuilder

    defwasm do
      memory(export(:mem), 1)

      func answer, result: :i32 do
        42
      end
    end
  end

  test "defwasm/1 defines __wasm_module__/0" do
    alias ComponentsGuide.Rustler.WasmBuilder

    wasm = SingleFunc.__wasm_module__()

    assert wasm == %WasmBuilder.Module{
             name: "SingleFunc",
             body: [
               %WasmBuilder.Memory{name: {:export, :mem}, min: 1},
               %WasmBuilder.Func{
                 name: {:export, :answer},
                 params: [],
                 result: {:result, :i32},
                 body: [42]
               }
             ]
           }
  end

  test "to_wat/1 defwasm" do
    wasm_source = """
    (module $SingleFunc
      (memory (export "mem") 1)
      (func (export "answer") (result i32)
        i32.const 42
      )
    )
    """

    assert to_wat(SingleFunc) == wasm_source
  end

  test "to_wat/1 defwasmmodule single func" do
    alias ComponentsGuide.Rustler.WasmBuilder

    wasm =
      defwasmmodule SomeName do
        memory(export(:mem), 1)

        func answer, result: :i32 do
          42
        end
      end

    assert wasm == %WasmBuilder.Module{
             name: "SomeName",
             body: [
               %WasmBuilder.Memory{name: {:export, :mem}, min: 1},
               %WasmBuilder.Func{
                 name: {:export, :answer},
                 body: [42],
                 params: [],
                 result: {:result, :i32}
               }
             ]
           }

    wasm_source = """
    (module $SomeName
      (memory (export "mem") 1)
      (func (export "answer") (result i32)
        i32.const 42
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
        memory(export(:mem), 1)

        func answer, result: :i32 do
          2
          21
          i32(:mul)
        end

        func get_pi, result: :f32 do
          3.14
        end
      end

    wasm_source = """
    (module $two_funcs
      (memory (export "mem") 1)
      (func (export "answer") (result i32)
        i32.const 2
        i32.const 21
        i32.mul
      )
      (func (export "get_pi") (result f32)
        f32.const 3.14
      )
    )
    """

    assert to_wat(wasm) == wasm_source
  end

  @statuses [
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

  test "to_wat/1 many data" do
    wasm =
      defwasmmodule string_html do
        wasm_import(:env, :buffer, memory(1))

        for {status, message} <- @statuses do
          data(status * 24, "#{message}\\00")
        end

        func lookup(status(:i32)), result: :i32 do
          local_get(status)
          24
          i32(:mul)
        end
      end

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

  defmodule WithinRange do
    use WasmBuilder

    defwasm do
      func validate(num(:i32)), result: :i32 do
        # lt is_integer()
        # gt is_integer()
        local(:lt, :i32)
        local(:gt, :i32)
        local_get(:num)
        1
        i32(:lt_s)
        local_set(:lt)
        local_get(:num)
        255
        i32(:gt_s)
        local_set(:gt)
        local_get(:lt)
        local_get(:gt)
        i32(:or)
        i32(:eqz)
      end

      # export(:validate, validate)
    end
  end

  test "wasm_example/3 checking a number is within a range" do
    wasm_source = """
    (module $WithinRange
      (func (export "validate") (param $num i32) (result i32)
        local $lt i32
        local $gt i32
        local.get $num
        i32.const 1
        i32.lt_s
        local.set $lt
        local.get $num
        i32.const 255
        i32.gt_s
        local.set $gt
        local.get $lt
        local.get $gt
        i32.or
        i32.eqz
      )
    )
    """

    assert to_wat(WithinRange) == wasm_source
  end

  # defwasm multiply(a, b) do
  #   Build.func multiply(a, b) do
  #     I32.mul(a, b)
  #   end
  # end

  # defwasmmodule multiply do
  #   Build.func multiply(a, b) do
  #     I32.mul(a, b)
  #   end
  #   export(multiply)
  # end
end
