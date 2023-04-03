defmodule ComponentsGuide.Wasm.WasmExamplesTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Wasm.WasmExamples.{HTMLPage, Counter}

  describe "HTMLPage constructs an HTML response" do
    test "good request" do
      # IO.puts(HTMLPage.to_wat())

      offset = Wasm.call(HTMLPage, "get_request_body_write_offset")
      write_request = {:write_string, offset, "good", true}
      # write_request = {:write_string, offset, nil_terminated("good")}

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

      assert chunks == ["content-type: text/html;charset=utf-8\r\n", "<!doctype html>", "<h1>Good</h1>"]

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
        Wasm.instance_call_returning_string(instance, "next_body_chunk"),
      ]

      assert chunks == ["content-type: text/html;charset=utf-8\r\n", "<!doctype html>", "<h1>Good</h1>"]
    end

    test "good request (instance generated module functions)" do
      instance = HTMLPage.start() # Like Agent.start(fun)

      offset = HTMLPage.get_request_body_write_offset(instance)
      HTMLPage.write_string_nul_terminated(instance, offset, "good")

      status = HTMLPage.get_status(instance)
      assert status == 200

      chunks = [
        HTMLPage.get_headers(instance),
        HTMLPage.next_body_chunk(instance),
        HTMLPage.next_body_chunk(instance),
      ]

      assert chunks == ["content-type: text/html;charset=utf-8\r\n", "<!doctype html>", "<h1>Good</h1>"]
    end

    test "bad request" do
      offset = Wasm.call(HTMLPage, "get_request_body_write_offset")
      write_request = {:write_string, offset, "bad", true}

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

      # dbg(HTMLPage.to_wat())
      assert chunks == ["content-type: text/html;charset=utf-8\r\n", "<!doctype html>", "<h1>Bad</h1>"]

      # assert Wasm.call_string(HTMLPage, "next_body_chunk") == "<!doctype html>"
    end
  end

  describe "Counter" do
    test "works" do
      instance = Counter.start() # Like Agent.start(fun)
      assert Counter.get_current(instance) == 0

      Counter.increment(instance)
      assert Counter.get_current(instance) == 1

      Counter.increment(instance)
      assert Counter.get_current(instance) == 2
    end
  end
end
