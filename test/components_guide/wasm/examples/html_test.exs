defmodule ComponentsGuide.Wasm.Examples.HTMLTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance

  alias ComponentsGuide.Wasm.Examples.HTML.{
    EscapeHTML,
    HTMLPage,
    CounterHTML,
    SitemapBuilder,
    HTMLFormBuilder
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
               {:memory, "memory"},
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

  describe "CounterHTML" do
    test "list exports" do
      assert CounterHTML.exports() == [
               {:memory, "memory"},
               {:func, "get_current"},
               {:func, "increment"},
               {:func, "rewind"},
               {:func, "next_body_chunk"}
             ]
    end

    test "compiles small" do
      assert byte_size(CounterHTML.to_wasm()) == 501
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

  describe "SitemapBuilder" do
    test "works" do
      instance = Instance.run(SitemapBuilder)

      add_url = Instance.capture(instance, :add_url, 1)

      add_url.("https://example.org/a=1&b=2&c=3")
      add_url.("https://example.com/")

      body = SitemapBuilder.read_body(instance)

      assert body == """
             <?xml version="1.0" encoding="UTF-8"?>
             <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
             <url>
             <loc>https://example.org/a=1&amp;b=2&amp;c=3</loc>
             </url>
             <url>
             <loc>https://example.com/</loc>
             </url>
             </urlset>
             """
    end
  end

  describe "HTMLFormBuilder" do
    # @tag :skip
    test "works" do
      instance = HTMLFormBuilder.start()

      # form = [
      #   [:textbox, "first_name"],
      #   [:textbox, "last_name"],
      # ]

      add_textbox = Instance.capture(instance, :add_textbox, 1)

      add_textbox.("name")
      add_textbox.("bio")
      add_textbox.("website")

      # Instance.log_memory(instance, 64 * 1024, 100)

      html = HTMLFormBuilder.read_body(instance)

      assert html == ~S"""
             <form>
             <label for="name">
               <input type="text" name="name">
             </label>
             <label for="bio">
               <input type="text" name="bio">
             </label>
             <label for="website">
               <input type="text" name="website">
             </label>
             </form>
             """
    end
  end
end
