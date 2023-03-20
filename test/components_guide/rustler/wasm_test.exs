defmodule ComponentsGuide.Rustler.WasmTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Rustler.WasmBuilder

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
      (func $internal (result f32)
        f32.const 99
      )
    )
    """

    assert Wasm.wasm_list_exports({:wat, wasm_source}) == [
             {:func, "answer"},
             {:memory, "mem"},
             {:func, "get_pi"}
           ]
  end

  test "call/2" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    assert Wasm.call(wasm_source, "answer") == 42
  end

  test "call/2 uninitialized local" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
        (local $a i32)
        local.get $a
      )
    )
    """

    assert Wasm.call(wasm_source, "answer") == 0
  end

  test "call/2 mutating a param" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (param $a i32) (result i32)
        (i32.const 42)
        (local.set $a)
        (local.get $a)
      )
    )
    """

    assert Wasm.call(wasm_source, "answer", 17) == 42
  end

  test "call/4 adding two numbers" do
    wasm_source = """
    (module $add_func
      (func $add (param $a i32) (param $b i32) (result i32)
        (local.get $a)
        (local.get $b)
        (i32.add)
      )
      (export "add" (func $add))
    )
    """

    assert Wasm.call(wasm_source, "add", 7, 5) == 12
  end

  defmodule Add2Ints do
    use ComponentsGuide.Rustler.WasmBuilder

    defwasm do
      func add(a(:i32), b(:i32)), result: :i32 do
        local_get(a)
        local_get(b)
        i32(:add)
      end
    end
  end

  test "call/4 defwasm adding two numbers" do
    assert Wasm.call(Add2Ints, "add", 7, 5) == 12
  end

  test "call/4 multiplying two numbers" do
    wasm_source = """
    (module $multiply_func
      (func $multiply (param $a i32) (param $b i32) (result i32)
        (local.get $a)
        (local.get $b)
        (i32.mul)
      )
      (export "multiply" (func $multiply))
    )
    """

    assert Wasm.call(wasm_source, "multiply", 7, 5) == 35
  end

  test "call/3 checking a number is within a range" do
    wasm_source = """
    (module $range_func
      (func $validate (param $num i32) (result i32)
        (local $lt i32)
        (local $gt i32)
        (i32.lt_s (local.get $num) (i32.const 1))
        (local.set $lt)
        (i32.gt_s (local.get $num) (i32.const 255))
        (local.set $gt)
        (i32.or (local.get $lt) (local.get $gt))
        (i32.eqz)
      )
      (export "validate" (func $validate))
    )
    """

    assert Wasm.call(wasm_source, "validate", -1) == 0
    assert Wasm.call(wasm_source, "validate", 0) == 0
    assert Wasm.call(wasm_source, "validate", 1) == 1
    assert Wasm.call(wasm_source, "validate", 2) == 1
    assert Wasm.call(wasm_source, "validate", 10) == 1
    assert Wasm.call(wasm_source, "validate", 13) == 1
    assert Wasm.call(wasm_source, "validate", 255) == 1
    assert Wasm.call(wasm_source, "validate", 256) == 0
    assert Wasm.call(wasm_source, "validate", 257) == 0
    assert Wasm.call(wasm_source, "validate", 2000) == 0
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

    assert Wasm.call(wasm_source, "main") == {256, 30}
    assert Wasm.call_string(wasm_source, "main") == "Know the length of this string"
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

    assert Wasm.call(wasm_source, "main") == 256
    assert Wasm.call_string(wasm_source, "main") == "No need to know the length of this string"
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

    assert Wasm.call(wasm_source, "main") == {65536, 15}
    assert Wasm.call_string(wasm_source, "main") == "<!doctype html>"
  end

  test "wasm_string/2 looks up HTTP status" do
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
        (local.get $status)
        (i32.const 24)
        (i32.mul)
      )
    )
    """

    assert Wasm.call_string(wasm_source, "lookup", 200) == "OK"
    assert Wasm.call_string(wasm_source, "lookup", 201) == "Created"
    assert Wasm.call_string(wasm_source, "lookup", 204) == "No Content"
    assert Wasm.call_string(wasm_source, "lookup", 205) == "Reset Content"
    assert Wasm.call_string(wasm_source, "lookup", 301) == "Moved Permanently"
    assert Wasm.call_string(wasm_source, "lookup", 302) == "Found"
    assert Wasm.call_string(wasm_source, "lookup", 303) == "See Other"
    assert Wasm.call_string(wasm_source, "lookup", 304) == "Not Modified"
    assert Wasm.call_string(wasm_source, "lookup", 307) == "Temporary Redirect"
    assert Wasm.call_string(wasm_source, "lookup", 401) == "Unauthorized"
    assert Wasm.call_string(wasm_source, "lookup", 403) == "Forbidden"
    assert Wasm.call_string(wasm_source, "lookup", 404) == "Not Found"
    assert Wasm.call_string(wasm_source, "lookup", 405) == "Method Not Allowed"
    assert Wasm.call_string(wasm_source, "lookup", 409) == "Conflict"
    assert Wasm.call_string(wasm_source, "lookup", 412) == "Precondition Failed"
    assert Wasm.call_string(wasm_source, "lookup", 413) == "Payload Too Large"
    assert Wasm.call_string(wasm_source, "lookup", 422) == "Unprocessable Entity"
    assert Wasm.call_string(wasm_source, "lookup", 429) == "Too Many Requests"
    assert Wasm.call_string(wasm_source, "lookup", 100) == ""
    # Crashes:
    # assert Wasm.call_string(wasm_source, "lookup", -1) == ""
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
      func insert(element(:i32)) do
        count = I32.add(count, 1)
        tally = I32.add(tally, element)
      end

      func calculate_mean(), result: :i32 do
        I32.div_u(tally, count)
      end
    end
  end

  test "bulk_call/2 global calculates mean" do
    [nil, nil, nil, result] =
      Wasm.bulk_call(CalculateMean, [
        {"insert", [5]},
        {"insert", [7]},
        {"insert", [9]},
        {"calculate_mean", []}
      ])

    assert result == 7
  end

  defmodule HTMLPage do
    use WasmBuilder

    def hello, do: 4
    def hello2, do: "<!doctype html>"

    defwasm imports: [
              env: [buffer: memory(2)]
            ],
            globals: [
              count: i32(0)
            ] do
      # data_nil_terminated(4, hello2())
      data_nil_terminated(4, "<!doctype html>")
      data_nil_terminated(20, "<h1>Good</h1>")
      data_nil_terminated(40, "<h1>Bad</h1>")

      # defdata doctype, do: "<!doctype html>"
      # defdata good_heading, do: "<h1>Good</h1>"
      # defdata bad_heading, do: "<h1>Bad</h1>"

      # data_nil_terminated(4, :html,
      #   doctype: "<!doctype html>",
      #   good_heading: "<h1>Good</h1>",
      #   bad_heading: "<h1>Bad</h1>",
      # )

      func get_request_body_write_offset, result: :i32 do
        65536
      end

      funcp get_is_valid, result: :i32 do
        I32.eq(I32.load8_u(65536), ?g)
      end

      func get_status, result: :i32, locals: [is_valid: :i32] do
        is_valid = call(:get_is_valid)
        I32.if_else(is_valid, do: 200, else: 400)
      end

      func body, result: :i32, locals: [is_valid: :i32] do
        is_valid = call(:get_is_valid)
        count = I32.add(count, 1)

        # I32.if_else(I32.eq(count, 1),
        #   do: 4,
        #   else: I32.if_else(is_valid, do: 20, else: 40)
        # )
        # I32.if_else(I32.eq(count, 1),
        #   do: lookup_data(:doctype),
        #   else: I32.if_else(is_valid, do: lookup_data(:good_heading), else: lookup_data(:bad_heading))
        # )
        I32.if_else(I32.eq(count, 1),
          do: 4,
          else: I32.if_else(is_valid, do: 20, else: 40)
        )
      end
    end
  end

  describe "HTMLPage constructs an HTML response" do
    test "good request" do
      write_request = {:write_string, 65536, "good", true}
      # assert Wasm.call(HTMLPage, "is_valid") == 1

      [status] =
        Wasm.steps(HTMLPage, [
          write_request,
          {:call, "get_status", []}
        ])

      assert status == 200

      chunks =
        Wasm.steps(HTMLPage, [
          write_request,
          {:call_string, "body", []},
          {:call_string, "body", []}
        ])

      assert chunks == ["<!doctype html>", "<h1>Good</h1>"]

      # Wasm.steps(CalculateMean) do
      #   request_body_write_offset = Step.call("get_request_body_write_offset")
      #   Step.write_string(request_body_write_offset, "hello")
      #   body = Step.call_string("body")
      # end

      # assert Wasm.call_string(HTMLPage, "body") == "<!doctype html>"
    end

    test "bad request" do
      # assert Wasm.call(HTMLPage, "is_valid") == 0
      write_request = {:write_string, 65536, "bad", true}

      [status] =
        Wasm.steps(HTMLPage, [
          write_request,
          {:call, "get_status", []}
        ])

      assert status == 400

      chunks =
        Wasm.steps(HTMLPage, [
          write_request,
          {:call_string, "body", []},
          {:call_string, "body", []}
        ])

      # dbg(HTMLPage.to_wat())
      assert chunks == ["<!doctype html>", "<h1>Bad</h1>"]

      # assert Wasm.call_string(HTMLPage, "body") == "<!doctype html>"
    end
  end

  defmodule FileNameSafe do
    use WasmBuilder

    defwasm imports: [env: [buffer: memory(2)]] do
      func get_is_valid, result: :i32, locals: [i: :i32, char: :i32] do
        i = 1024

        defloop :continue, result: :i32 do
          defblock :outer do
            defblock :inner do
              char = I32.load8_u(i)
              br :inner, if: I32.eq(char, ?/)
              br :outer, if: char
              1
              return()
            end
            0
            return()
          end
          i = I32.add(i, 1)
          br :continue
        end
      end
    end
  end

  describe "returns if a string is file name safe" do
    [result] =
      Wasm.steps(FileNameSafe, [
        {:write_string, 1024, "good", true},
        {:call, "get_is_valid", []}
      ])

    assert result == 1

    [result] =
      Wasm.steps(FileNameSafe, [
        {:write_string, 1024, "has/slashes", true},
        {:call, "get_is_valid", []}
      ])

    assert result == 0
  end

  # test "global calculates mean" do
  #   instance = Wasm.start(CalculateMean)
  #   Wasm.call(instance, "insert", 1)
  #   Wasm.call(instance, "insert", 2)
  #   Wasm.call(instance, "insert", 3)

  #   assert Wasm.call(instance, "calculate_mean") == 2

  #   Wasm.stop(instance)
  # end

  # defwasm multiply(a, b) do
  #   Wasm.func multiply(a, b) do
  #     W32.mul(a, b)
  #   end
  # end
end
