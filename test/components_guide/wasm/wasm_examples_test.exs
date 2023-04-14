defmodule ComponentsGuide.Wasm.WasmExamplesTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Wasm

  alias ComponentsGuide.Wasm.WasmExamples.{
    EscapeHTML,
    HTMLPage,
    Counter,
    CounterHTML,
    Loader,
    SitemapBuilder,
    LamportClock
  }

  describe "EscapeHTML" do
    test "escape valid html" do
      # offset = Wasm.call(EscapeHTML, "get_request_body_write_offset")

      [count, result] =
        Wasm.steps(EscapeHTML, [
          {:write_string_nul_terminated, 1024, "https://example.org/a=1&b=2", true},
          {:call, "escape_html", []},
          {:read_memory, 2048, 40}
        ])

      result = String.trim_trailing(result, <<0>>)

      assert count == 31
      assert result == "https://example.org/a=1&amp;b=2"

      [count, result] =
        Wasm.steps(EscapeHTML, [
          {:write_string_nul_terminated, 1024, "Hall & Oates like M&Ms", true},
          {:call, "escape_html", []},
          {:read_memory, 2048, 40}
        ])

      result = String.trim_trailing(result, <<0>>)

      assert count == 30
      assert result == "Hall &amp; Oates like M&amp;Ms"

      [count, result] =
        Wasm.steps(EscapeHTML, [
          {:write_string_nul_terminated, 1024, ~s[1 < 2 & 2 > 1 "double quotes" 'single quotes'],
           true},
          {:call, "escape_html", []},
          {:read_memory, 2048, 100}
        ])

      result = String.trim_trailing(result, <<0>>)

      assert count == 73
      assert result == "1 &lt; 2 &amp; 2 &gt; 1 &quot;double quotes&quot; &#39;single quotes&#39;"
    end
  end

  describe "HTMLPage constructs an HTML response" do
    test "list exports" do
      assert HTMLPage.exports() == [
               {:global, "request_body_write_offset", :i32},
               {:func, "get_request_body_write_offset"},
               {:func, "GET"},
               {:func, "get_status"},
               {:func, "get_headers"},
               {:func, "next_body_chunk"}
             ]
    end

    test "good request (steps)" do
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

  describe "CounterHTML" do
    test "list exports" do
      assert CounterHTML.exports() == [
               {:func, "get_current"},
               {:func, "increment"},
               {:func, "invalidate"},
               {:func, "next_body_chunk"}
             ]
    end

    test "works" do
      # IO.puts(CounterHTML.to_wat())

      instance = CounterHTML.start()

      assert CounterHTML.read_body(instance) ==
               ~s[<output class="flex p-4 bg-gray-800">0</output>\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]

      CounterHTML.increment(instance)

      assert CounterHTML.read_body(instance) ==
               ~s[<output class="flex p-4 bg-gray-800">1</output>\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]

      CounterHTML.increment(instance)

      assert CounterHTML.read_body(instance) ==
               ~s[<output class="flex p-4 bg-gray-800">2</output>\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]

      CounterHTML.increment(instance)

      assert CounterHTML.read_body(instance) ==
               ~s[<output class="flex p-4 bg-gray-800">3</output>\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]

      CounterHTML.increment(instance)

      assert CounterHTML.read_body(instance) ==
               ~s[<output class="flex p-4 bg-gray-800">4</output>\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]

      for _ <- 1..10, do: CounterHTML.increment(instance)

      assert CounterHTML.read_body(instance) ==
               ~s[<output class="flex p-4 bg-gray-800">14</output>\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]
    end
  end

  describe "Loader" do
    test "exports" do
      assert Loader.exports() == [
               #  {{:global, "idle"}, %{type: :i32, mut: true}},
               #  {:global, %{name: "idle", type: :i32, mut: true}},
               {:global, "idle", :i32},
               {:global, "loading", :i32},
               {:global, "loaded", :i32},
               {:global, "failed", :i32},
               {:func, "get_current"},
               {:func, "begin"},
               {:func, "success"},
               {:func, "failure"}
             ]
    end

    test "works" do
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

  describe "SitemapBuilder" do
    test "works" do
      # IO.puts(SitemapBuilder.to_wat())
      instance = SitemapBuilder.start()

      SitemapBuilder.write_input(instance, "https://example.org/a=1&b=2&c=3")

      body = SitemapBuilder.read_body(instance)

      assert body == """
             <?xml version="1.0" encoding="UTF-8"?>
             <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
             <url>
             <loc>https://example.org/a=1&amp;b=2&amp;c=3</loc>
             </url>
             </urlset>
             """
    end
  end

  describe "LamportClock" do
    test "works" do
      a = LamportClock.start()
      b = LamportClock.start()

      assert LamportClock.received(a, 7) == 8

      LamportClock.send(a, b)

      assert LamportClock.read(a) == 9
      assert LamportClock.read(b) == 10
    end
  end

  describe "SimpleWeekdayParser" do
    alias ComponentsGuide.Wasm.WasmExamples.SimpleWeekdayParser

    test "works" do
      # IO.puts(SimpleWeekdayParser.to_wat())
      a = SimpleWeekdayParser.start()

      assert Wasm.instance_call(a, "parse") == 0

      Wasm.instance_write_string_nul_terminated(a, :input_offset, "Mon")
      assert Wasm.instance_call(a, "parse") == 1

      Wasm.instance_write_string_nul_terminated(a, :input_offset, "Mob")
      assert Wasm.instance_call(a, "parse") == 0

      Wasm.instance_write_string_nul_terminated(a, :input_offset, "Tua")
      assert Wasm.instance_call(a, "parse") == 0

      Wasm.instance_write_string_nul_terminated(a, :input_offset, "Tue")
      assert Wasm.instance_call(a, "parse") == 1

      Wasm.instance_write_string_nul_terminated(a, :input_offset, "Wed")
      assert Wasm.instance_call(a, "parse") == 1
    end
  end
end
