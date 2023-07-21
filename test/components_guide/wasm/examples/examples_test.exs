defmodule ComponentsGuide.Wasm.ExamplesTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.{Instance, Wasm}

  alias ComponentsGuide.Wasm.Examples

  describe "SimpleWeekdayParser" do
    alias Examples.SimpleWeekdayParser

    test "works" do
      # IO.puts(SimpleWeekdayParser.to_wat())
      # IO.inspect(byte_size(SimpleWeekdayParser.to_wasm()))
      a = Instance.run(SimpleWeekdayParser)

      assert SimpleWeekdayParser.parse(a) == 0

      SimpleWeekdayParser.set_input(a, "Mon")
      assert SimpleWeekdayParser.parse(a) == 1

      SimpleWeekdayParser.set_input(a, "Mob")
      assert SimpleWeekdayParser.parse(a) == 0

      SimpleWeekdayParser.set_input(a, "Tua")
      assert SimpleWeekdayParser.parse(a) == 0

      SimpleWeekdayParser.set_input(a, "Tue")
      assert SimpleWeekdayParser.parse(a) == 2

      SimpleWeekdayParser.set_input(a, "Wed")
      assert SimpleWeekdayParser.parse(a) == 3

      SimpleWeekdayParser.set_input(a, "Thu")
      assert SimpleWeekdayParser.parse(a) == 4

      SimpleWeekdayParser.set_input(a, "Fri")
      assert SimpleWeekdayParser.parse(a) == 5

      SimpleWeekdayParser.set_input(a, "Sat")
      assert SimpleWeekdayParser.parse(a) == 6

      SimpleWeekdayParser.set_input(a, "Sun")
      assert SimpleWeekdayParser.parse(a) == 7

      SimpleWeekdayParser.set_input(a, "Monday")
      assert SimpleWeekdayParser.parse(a) == 0
    end
  end

  describe "HTTPProxy" do
    alias Examples.HTTPProxy

    test "wat" do
      # IO.puts(HTTPProxy.to_wat())

      assert HTTPProxy.to_wat() =~
               ~S"""
               (module $HTTPProxy
                 (import "http" "get" (func $http_get (param i32) (result i32)))
                 (global $input_offset (export "input_offset") (mut i32) (i32.const 65536))
               """
    end

    test "list exports" do
      assert Wasm.list_import_types(HTTPProxy) == [
               {"http", "get", {:func, %{params: [:i32], results: [:i32]}}}
             ]
    end

    # FIXME
    @tag :skip
    test "works by using correct imported function" do
      instance = HTTPProxy.start()

      status = Instance.call(instance, "get_status")
      assert status == 200
    end
  end
end
