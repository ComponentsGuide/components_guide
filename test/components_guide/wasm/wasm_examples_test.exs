defmodule ComponentsGuide.Wasm.WasmExamplesTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Wasm.WasmExamples.{HTMLPage, Counter, Loader}

  describe "HTMLPage constructs an HTML response" do
    test "list exports" do
      assert HTMLPage.exports() == [
               {:global, "request_body_write_offset"},
               {:func, "get_request_body_write_offset"},
               {:func, "GET"},
               {:func, "get_status"},
               {:func, "get_headers"},
               {:func, "next_body_chunk"}
             ]
    end

    test "good request (steps)" do
      IO.puts(HTMLPage.to_wat())

      offset = Wasm.call(HTMLPage, "get_request_body_write_offset")
      write_request = {:write_string_nul_terminated, offset, "good", true}
      # write_request = {:write_string_nul_terminated, offset, nil_terminated("good")}

      [status] =
        Wasm.steps(HTMLPage, [
          write_request,
          {:call, "get_status", []}
        ])

      assert status == 200

      chunks =
        Wasm.steps(HTMLPage, [
          write_request,
          {:call_string, "get_headers", []},
          # {:apply, "get_headers", [], String},
          # {:string_call_repeatedly_until_nil, "next_body_chunk", []},
          # {:call_string_get_all_chunks, "next_body_chunk", []},
          # {:call_string_join_all_chunks, "next_body_chunk", []},
          # {:call_string_join_chunked, "next_body_chunk", []},
          # {:call_join_chunked_string, "next_body_chunk", []},
          {:call_string, "next_body_chunk", []},
          {:call_string, "next_body_chunk", []}
        ])

      assert chunks == [
               "content-type: text/html;charset=utf-8\r\n",
               "<!doctype html>",
               "<h1>Good</h1>"
             ]

      # Wasm.steps(CalculateMean) do
      #   request_body_write_offset = Step.call("get_request_body_write_offset")
      #   Step.write_string(request_body_write_offset, "hello")
      #   body = Step.call_string("next_body_chunk")
      # end

      # assert Wasm.call_string(HTMLPage, "next_body_chunk") == "<!doctype html>"
    end

    test "good request (instance)" do
      instance = Wasm.run_instance(HTMLPage)
      offset = Wasm.instance_call(instance, "get_request_body_write_offset")
      Wasm.instance_write_string_nul_terminated(instance, offset, "good")
      # instance.memory8[offset] = "good"

      status = Wasm.instance_call(instance, "get_status")
      assert status == 200

      chunks = [
        Wasm.instance_call_returning_string(instance, "get_headers"),
        Wasm.instance_call_returning_string(instance, "next_body_chunk"),
        Wasm.instance_call_returning_string(instance, "next_body_chunk")
      ]

      assert chunks == [
               "content-type: text/html;charset=utf-8\r\n",
               "<!doctype html>",
               "<h1>Good</h1>"
             ]
    end

    test "good request (instance generated module functions)" do
      # Like Agent.start(fun)
      instance = HTMLPage.start()

      HTMLPage.set_request_body(instance, "good")

      assert HTMLPage.get_status(instance) == 200
      assert HTMLPage.get_headers(instance) == "content-type: text/html;charset=utf-8\r\n"

      body = HTMLPage.read_body(instance)
      assert body == "<!doctype html><h1>Good</h1>"
    end

    test "can change global request body offset" do
      # Like Agent.start(fun)
      instance = HTMLPage.start()

      HTMLPage.set_request_body_write_offset(instance, 2048)
      HTMLPage.write_string_nul_terminated(instance, 2048, "good")

      assert HTMLPage.get_status(instance) == 200
    end

    test "bad request" do
      offset = Wasm.call(HTMLPage, "get_request_body_write_offset")
      write_request = {:write_string_nul_terminated, offset, "bad", true}

      [status] =
        Wasm.steps(HTMLPage, [
          write_request,
          {:call, "get_status", []}
        ])

      assert status == 400

      chunks =
        Wasm.steps(HTMLPage, [
          write_request,
          {:call_string, "get_headers", []},
          {:call_string, "next_body_chunk", []},
          {:call_string, "next_body_chunk", []}
        ])

      assert chunks == [
               "content-type: text/html;charset=utf-8\r\n",
               "<!doctype html>",
               "<h1>Bad</h1>"
             ]

      # assert Wasm.call_string(HTMLPage, "next_body_chunk") == "<!doctype html>"
    end
  end

  describe "Counter" do
    test "list exports" do
      assert Counter.exports() == [
               {:func, "get_current"},
               {:func, "increment"}
             ]
    end

    test "works" do
      # Like Agent.start(fun)
      instance = Counter.start()
      assert Counter.get_current(instance) == 0

      Counter.increment(instance)
      assert Counter.get_current(instance) == 1

      Counter.increment(instance)
      assert Counter.get_current(instance) == 2
    end
  end

  describe "Loader" do
    test "works" do
      IO.puts(Loader.to_wat())
      # Like Agent.start(fun)
      a = Loader.start()
      # assert Loader.get_current(a) == Loader.get_global(a, "idle")
      assert Loader.get_current(a) == 0
      Loader.begin(a)
      assert Loader.get_current(a) == 1
      Loader.success(a)
      assert Loader.get_current(a) == 2

      b = Loader.start()
      assert Loader.get_current(b) == 0

      Loader.success(b)
      assert Loader.get_current(b) == 0
      Loader.failure(b)
      assert Loader.get_current(b) == 0

      Loader.begin(b)
      assert Loader.get_current(b) == 1
      Loader.failure(b)
      assert Loader.get_current(b) == 3
    end
  end
end
