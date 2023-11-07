defmodule ComponentsGuide.Wasm.Examples do
  alias OrbWasmtime.Instance

  defmodule SimpleWeekdayParser do
    use Orb

    @weekdays_i32 (for s <- ~w(Mon Tue Wed Thu Fri Sat Sun) do
                     #  I32.from_4_byte_ascii(s <> <<0>>)
                     I32.from_4_byte_ascii(s <> "\0")
                     #  I32.from_4_byte_ascii("#{s}\0")
                   end)

    Memory.pages(1)
    I32.export_global(:mutable, input_offset: 1024)

    wasm do
      func parse(), I32, i: I32 do
        # If does no end in nul byte, return 0
        if Memory.load!(I32.U8, I32.add(@input_offset, 3)) do
          return(0)
        end

        # Write nul byte at end
        Memory.store!(I32.U8, I32.add(@input_offset, 3), 0)
        i = Memory.load!(I32, @input_offset)

        # Check equality to each weekday as a i32 e.g. `Mon\0`
        inline for {day_i32!, index!} <- Enum.with_index(@weekdays_i32, 1) do
          wasm do
            if I32.eq(i, day_i32!), do: return(index!)
          end
        end

        0
      end
    end

    def set_input(instance, string),
      do: Instance.write_string_nul_terminated(instance, :input_offset, string)

    def parse(instance), do: Instance.call(instance, "parse")
  end

  defmodule OldOrb do
    def pack_strings_nul_terminated(start_offset, strings_record) do
      {lookup_table, _} =
        Enum.map_reduce(strings_record, start_offset, fn {key, string}, offset ->
          {{key, %{offset: offset, string: string}}, offset + byte_size(string) + 1}
        end)

      Map.new(lookup_table)
    end
  end

  defmodule ContentTypeLookup do
    use Orb

    @readonly_start 0xFF
    @strings OldOrb.pack_strings_nul_terminated(@readonly_start,
               charset_utf8: ~S[; charset=utf-8],
               text_plain: ~S[text/plain],
               text_html: ~S[text/html],
               application_json: ~S[application/json],
               application_wasm: ~S[application/wasm],
               image_png: ~S[image/png]
             )

    I32.global(chunk1: 0, chunk2: 0)

    wasm do
      func txt do
        @chunk1 = inline do: @strings.text_plain.offset
        @chunk2 = inline do: @strings.charset_utf8.offset
      end

      func html do
        @chunk1 = inline do: @strings.text_html.offset
        @chunk2 = inline do: @strings.charset_utf8.offset
      end

      func json do
        @chunk1 = inline do: @strings.application_json.offset
        @chunk2 = inline do: @strings.charset_utf8.offset
      end

      func wasm do
        @chunk1 = inline do: @strings.application_wasm.offset
        @chunk2 = 0x0
      end

      func png do
        @chunk1 = inline do: @strings.image_png.offset
        @chunk2 = 0x0
      end
    end

    # def set_input(instance, string),
    #   do: Instance.write_string_nul_terminated(instance, :input_offset, string)

    # def parse(instance), do: Instance.call(instance, "parse")
  end

  defmodule HTTPProxy do
    use Orb

    @page_size 64 * 1024
    # @readonly_start 0xFF
    @input_offset 1 * @page_size

    wasm_import(:http,
      get: Orb.DSL.funcp(name: :http_get, params: I32, result: I32)
    )

    I32.export_global(:mutable, input_offset: @input_offset)

    wasm do
      func get_status(), I32 do
        # 500
        typed_call(I32, :http_get, [0])
      end
    end

    def start() do
      imports = [
        {:http, :get, fn _address -> 200 end}
        # {:http, :get, fn instance, address ->
        #   url_string = Instance.read_string(instance, address)
        #   resp = Fetch.get!(url_string)
        #   resp.status
        # end}
        # http: [
        #   func get(address: I32), I32 do
        #     200
        #   end
        # ]

        # http: [
        #   get: fn _address ->
        #     200
        #   end
        # ]
      ]

      OrbWasmtime.Instance.run(__MODULE__, imports)
    end
  end

  defmodule WebPageIntegrationTest do
    use Orb

    wasm_import(:navigate,
      visit: Orb.DSL.funcp(name: :visit, params: I32, result: I32)
    )
    wasm_import(:query,
      get_by_role: Orb.DSL.funcp(name: :get_by_role, params: I32, result: I32),
      expect_by_role: Orb.DSL.funcp(name: :get_by_role, params: {I32, I32})
    )

    wasm do
      func test_home_page(), I32 do
        # imports.visit("/")
        # imports.expect_by_role("link", "Home")
        typed_call(I32, :visit, [const("/")])
        typed_call(I32, :expect_by_role, [const("link"), const("Home")])
      end
    end
  end

  defmodule TailwindLike do
    use Orb

    wasm_import(:navigate,
      visit: Orb.DSL.funcp(name: :visit, params: I32, result: I32)
    )
    wasm_import(:query,
      get_by_role: Orb.DSL.funcp(name: :get_by_role, params: I32, result: I32),
      expect_by_role: Orb.DSL.funcp(name: :get_by_role, params: I32)
    )

    wasm do
      func test_home_page(), I32.String do
        # imports.visit("/")
        # imports.expect_by_role("link", "Home")
        ~S[<button class="text-lg">Click me</button>]
        # _css = const_set_insert(:css, ~s[.text-lg{font-size: 125%}])
        # css = const_list_append(:css, ~s[.text-lg{font-size: 125%}])

        # wind(~s[<button class="text-lg">Click me</button>])
      end
    end
  end

  defmodule FormState do
    use Orb

    wasm do
      func on_input(input_name: I32, string_value: I32) do
        # TODO: store string_value under key input_name
        # TODO: add funcs like Keyword.put() to the LinkedLists wasm module
      end

      func on_reset() do
      end

      func to_urlencoded(), I32 do
        -1
      end
    end
  end

  defmodule Base64Encode do
  end

  defmodule GzipCompress do
  end

  defmodule URLParser do
    # Lets you extract out host, path, query params.
  end
end
