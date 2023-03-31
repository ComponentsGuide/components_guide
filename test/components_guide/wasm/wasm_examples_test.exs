defmodule ComponentsGuide.Wasm.WasmExamplesTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Wasm.WasmExamples.{HTMLPage}

  describe "HTMLPage constructs an HTML response" do
    test "good request" do
      offset = Wasm.call(HTMLPage, "get_request_body_write_offset")
      write_request = {:write_string, offset, "good", true}

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
          # {:call_string_repeatedly_until_nil, "body", []},
          {:call_string, "body", []},
          {:call_string, "body", []}
        ])

      assert chunks == ["content-type: text/html;charset=utf-8\r\n", "<!doctype html>", "<h1>Good</h1>"]

      # Wasm.steps(CalculateMean) do
      #   request_body_write_offset = Step.call("get_request_body_write_offset")
      #   Step.write_string(request_body_write_offset, "hello")
      #   body = Step.call_string("body")
      # end

      # assert Wasm.call_string(HTMLPage, "body") == "<!doctype html>"
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
          {:call_string, "body", []},
          {:call_string, "body", []}
        ])

      # dbg(HTMLPage.to_wat())
      assert chunks == ["content-type: text/html;charset=utf-8\r\n", "<!doctype html>", "<h1>Bad</h1>"]

      # assert Wasm.call_string(HTMLPage, "body") == "<!doctype html>"
    end
  end
end
