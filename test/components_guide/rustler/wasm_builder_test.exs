defmodule ComponentsGuide.Rustler.WasmBuilderTest do
  use ExUnit.Case, async: true

  use ComponentsGuide.Rustler.WasmBuilder
  alias ComponentsGuide.Rustler.WasmBuilder

  test "func" do
    wasm =
      func answer, result: I32 do
        42
      end

    wasm_source = """
    (func (export "answer") (result i32)
      (i32.const 42)
    )\
    """

    assert to_wat(wasm) == wasm_source
  end

  defmodule SingleFunc do
    use ComponentsGuide.Rustler.WasmBuilder

    defwasm do
      memory(export(:mem), 1)

      func answer, result: I32 do
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
                 local_types: [],
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
        (i32.const 42)
      )
    )
    """

    assert to_wat(SingleFunc) == wasm_source
  end

  defmodule ManyFuncs do
    defwasm do
      memory(export(:mem), 1)

      func answer, result: I32 do
        I32.mul(2, 21)
      end

      func get_pi, result: :f32 do
        3.14
      end

      funcp internal, result: :f32 do
        99.0
      end
    end
  end

  test "to_wat/1 defwasm many funcs" do
    wasm_source = """
    (module $ManyFuncs
      (memory (export "mem") 1)
      (func (export "answer") (result i32)
        (i32.mul (i32.const 2) (i32.const 21))
      )
      (func (export "get_pi") (result f32)
        (f32.const 3.14)
      )
      (func $internal (result f32)
        (f32.const 99.0)
      )
    )
    """

    assert to_wat(ManyFuncs) == wasm_source
  end

  defmodule HTTPStatusLookup do
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

    defwasm do
      wasm_import(:env, :buffer, memory(1))

      for {status, message} <- @statuses do
        data(status * 24, "#{message}\\00")
      end

      func lookup(status(I32)), result: I32 do
        I32.mul(status, 24)
      end
    end
  end

  test "to_wat/1 many data" do
    wasm_source = ~s"""
    (module $HTTPStatusLookup
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
        (i32.mul (local.get $status) (i32.const 24))
      )
    )
    """

    assert to_wat(HTTPStatusLookup) == wasm_source
  end

  defmodule WithinRange do
    use WasmBuilder

    defwasm do
      func validate(num(I32)), result: I32, locals: [lt: I32, gt: I32] do
        lt = I32.lt_s(num, 1)
        gt = I32.gt_s(num, 255)

        I32.or(lt, gt)
        I32.eqz()
      end
    end
  end

  test "checking a number is within a range" do
    alias ComponentsGuide.Rustler.Wasm

    wasm_source = """
    (module $WithinRange
      (func (export "validate") (param $num i32) (result i32)
        (local $lt i32)
        (local $gt i32)
        (i32.lt_s (local.get $num) (i32.const 1))
        (local.set $lt)
        (i32.gt_s (local.get $num) (i32.const 255))
        (local.set $gt)
        (i32.or (local.get $lt) (local.get $gt))
        (i32.eqz)
      )
    )
    """

    assert to_wat(WithinRange) == wasm_source
    assert Wasm.call(WithinRange, "validate", 0) == 0
    assert Wasm.call(WithinRange, "validate", 1) == 1
    assert Wasm.call(WithinRange, "validate", 100) == 1
    assert Wasm.call(WithinRange, "validate", 255) == 1
    assert Wasm.call(WithinRange, "validate", 256) == 0
  end

  defmodule CalculateMean do
    use WasmBuilder

    defwasm imports: [
              env: [buffer: memory(1)]
            ],
            globals: [
              count: i32(0),
              tally: i32(0)
            ] do
      func insert(element(I32)) do
        count = I32.add(count, 1)
        tally = I32.add(tally, element)
      end

      func calculate_mean(), result: I32 do
        I32.div_u(tally, count)
      end

      # func calculate_mean(), result: I32 do
      #   I32.div_u(global_get(:tally), global_get(:count))
      # end
    end
  end

  test "stateful module calculating mean" do
    alias ComponentsGuide.Rustler.Wasm

    wasm_source = """
    (module $CalculateMean
      (import "env" "buffer" (memory 1))
      (global $count (mut i32) (i32.const 0))
      (global $tally (mut i32) (i32.const 0))
      (func (export "insert") (param $element i32)
        (i32.add (global.get $count) (i32.const 1))
        (global.set $count)
        (i32.add (global.get $tally) (local.get $element))
        (global.set $tally)
      )
      (func (export "calculate_mean") (result i32)
        (i32.div_u (global.get $tally) (global.get $count))
      )
    )
    """

    assert to_wat(CalculateMean) == wasm_source
    assert Wasm.call(CalculateMean, "insert", 0) == nil
  end

  defmodule FileNameSafe do
    use WasmBuilder

    defwasm imports: [env: [buffer: memory(2)]] do
      func get_is_valid, result: I32, locals: [i: I32, char: I32] do
        i = 1024

        defloop :continue, result: I32 do
          defblock Outer do
            defblock :inner do
              char = I32.load8_u(i)
              br_if(:inner, I32.eq(char, ?/))
              br_if(Outer, local_get(:char))
              return 1
            end
            return 0
          end
          i = I32.add(i, 1)
          br :continue
        end
      end
    end
  end

  test "loop" do
    wasm_source = """
    (module $FileNameSafe
      (import "env" "buffer" (memory 2))
      (func (export "get_is_valid") (result i32)
        (local $i i32)
        (local $char i32)
        (i32.const 1024)
        (local.set $i)
        (loop $continue (result i32)
          (block $Outer
            (block $inner
              (i32.load8_u (local.get $i))
              (local.set $char)
              (i32.eq (local.get $char) (i32.const 47))
              br_if $inner
              (local.get $char)
              br_if $Outer
              return (i32.const 1)
            )
            return (i32.const 0)
          )
          (i32.add (local.get $i) (i32.const 1))
          (local.set $i)
          br $continue
        )
      )
    )
    """

    assert to_wat(FileNameSafe) == wasm_source
    # assert Wasm.call(FileNameSafe, "body") == 100
  end
end
