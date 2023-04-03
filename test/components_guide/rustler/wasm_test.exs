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

  test "instance_call/2" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    instance = Wasm.run_instance(wasm_source)
    assert Wasm.instance_call(instance, "answer") == 42
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
      func add(a(I32), b(I32)), result: I32 do
        local_get(:a)
        local_get(:b)
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

    validate = &Wasm.call(wasm_source, "validate", &1)
    assert validate.(-1) == 0
    assert validate.(0) == 0
    assert validate.(1) == 1
    assert validate.(2) == 1
    assert validate.(10) == 1
    assert validate.(13) == 1
    assert validate.(255) == 1
    assert validate.(256) == 0
    assert validate.(257) == 0
    assert validate.(2000) == 0

    instance = Wasm.run_instance(wasm_source)
    # validate = Wasm.instance_get_func_i32(validate: 1)
    validate = &Wasm.instance_call(instance, "validate", &1)
    assert validate.(0) == 0
    assert validate.(1) == 1
    assert validate.(255) == 1
    assert validate.(256) == 0
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
      func insert(element(I32)) do
        count = I32.add(count, 1)
        tally = I32.add(tally, element)
      end

      func calculate_mean(), result: I32 do
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

  defmodule FileNameSafe do
    use WasmBuilder

    defwasm imports: [env: [buffer: memory(2)]] do
      func get_is_valid, result: I32, locals: [read_offset: I32, char: I32] do
        read_offset = 1024

        defloop Continue, result: I32 do
          defblock Outer do
            defblock Inner do
              # char = I32.load8_u(read_offset)
              # char = I32.Memory.load!(read_offset)
              # char = I32.Memory.load8!(read_offset).unsigned
              # char = I32.memory![read_offset].unsigned
              char = I32.memory8!(read_offset).unsigned
              # char = memory32_8![read_offset].unsigned
              br(Inner, if: I32.eq(char, ?/))
              br(Outer, if: char)
              push(1)
              return()
            end

            push(0)
            return()
          end

          read_offset = I32.add(read_offset, 1)
          br(Continue)
        end
      end
    end
  end

  test "returns if a string is file name safe" do
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

  defmodule CopyString do
    use WasmBuilder

    defwasm imports: [env: [buffer: memory(2)]] do
      func do_copy, result: I32, locals: [read_offset: I32, char: I32] do
        read_offset = 1024

        defloop EachChar, result: I32 do
          defblock Outer do
            # char = I32.memory8!(read_offset).unsigned
            # I32.memory8!(I32.add(read_offset, 1024), char)
            # char = I32.Memory8.load!(read_offset).unsigned
            # I32.Memory8.store!(I32.add(read_offset, 1024), char)

            char = memory32_8![read_offset].unsigned
            memory32_8![I32.add(read_offset, 1024)] = char

            # char = I32.load8_u(read_offset)
            # I32.store8(I32.add(read_offset, 1024), char)
            br(Outer, if: char)
            # Outer.branch(if: char)
            push(I32.sub(read_offset, 1024))
            return()
          end

          read_offset = I32.add(read_offset, 1)
          br(EachChar)
          # EachChar.branch()
        end
      end
    end
  end

  test "copies string bytes" do
    [len, result] =
      Wasm.steps(CopyString, [
        {:write_string, 1024, "good", true},
        {:call, "do_copy", []},
        {:read_memory, 2048, 4}
      ])

    assert len == 4
    assert result == "good"
  end

  defmodule EscapeHTML do
    use WasmBuilder

    defwasm imports: [env: [buffer: memory(2)]] do
      func escape_html, result: I32, locals: [read_offset: I32, write_offset: I32, char: I32] do
        read_offset = 1024
        write_offset = 1024 + 1024

        defloop EachChar, result: I32 do
          defblock Outer do
            char = memory32_8![read_offset].unsigned

            if I32.eq(char, ?&) do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?a
              memory32_8![I32.add(write_offset, 2)] = ?m
              memory32_8![I32.add(write_offset, 3)] = ?p
              memory32_8![I32.add(write_offset, 4)] = ?;
              write_offset = I32.add(write_offset, 4)
              br(Outer)
            end

            if I32.eq(char, ?<) do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?l
              memory32_8![I32.add(write_offset, 2)] = ?t
              memory32_8![I32.add(write_offset, 3)] = ?;
              write_offset = I32.add(write_offset, 3)
              br(Outer)
            end

            if I32.eq(char, ?>) do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?g
              memory32_8![I32.add(write_offset, 2)] = ?t
              memory32_8![I32.add(write_offset, 3)] = ?;
              write_offset = I32.add(write_offset, 3)
              br(Outer)
            end

            if I32.eq(char, ?") do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?q
              memory32_8![I32.add(write_offset, 2)] = ?u
              memory32_8![I32.add(write_offset, 3)] = ?o
              memory32_8![I32.add(write_offset, 4)] = ?t
              memory32_8![I32.add(write_offset, 5)] = ?;
              write_offset = I32.add(write_offset, 5)
              br(Outer)
            end

            if I32.eq(char, ?') do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?#
              memory32_8![I32.add(write_offset, 2)] = ?3
              memory32_8![I32.add(write_offset, 3)] = ?9
              memory32_8![I32.add(write_offset, 4)] = ?;
              write_offset = I32.add(write_offset, 4)
              br(Outer)
            end

            memory32_8![write_offset] = char
            br(Outer, if: char)

            # br(Outer, if: char)
            # Outer.branch(if: char)
            # Outer.if(char)
            push(I32.sub(write_offset, 1024 + 1024))
            return()
          end

          read_offset = I32.add(read_offset, 1)
          write_offset = I32.add(write_offset, 1)
          br(EachChar)
        end
      end
    end
  end

  test "escapes html" do
    # dbg(EscapeHTML.to_wat())

    [count, result] =
      Wasm.steps(EscapeHTML, [
        {:write_string, 1024, "hello", true},
        {:call, "escape_html", []},
        {:read_memory, 2048, 5}
      ])

    assert count == 5
    assert result == "hello"

    [count, result] =
      Wasm.steps(EscapeHTML, [
        {:write_string, 1024, "Hall & Oates like M&Ms", true},
        {:call, "escape_html", []},
        {:read_memory, 2048, 40}
      ])

    result = String.trim_trailing(result, <<0>>)

    assert count == 30
    assert result == "Hall &amp; Oates like M&amp;Ms"

    [count, result] =
      Wasm.steps(EscapeHTML, [
        {:write_string, 1024, ~s[1 < 2 & 2 > 1 "double quotes" 'single quotes'], true},
        {:call, "escape_html", []},
        {:read_memory, 2048, 100}
      ])

    result = String.trim_trailing(result, <<0>>)

    assert count == 73
    assert result == "1 &lt; 2 &amp; 2 &gt; 1 &quot;double quotes&quot; &#39;single quotes&#39;"
  end
end
