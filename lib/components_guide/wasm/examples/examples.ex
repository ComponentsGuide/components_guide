defmodule ComponentsGuide.Wasm.Examples do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

  defmodule SimpleWeekdayParser do
    use Wasm

    @weekdays_i32 (for s <- ~w(Mon Tue Wed Thu Fri Sat Sun) do
                    #  I32.from_4_byte_ascii(s <> <<0>>)
                     I32.from_4_byte_ascii(s <> "\0")
                    #  I32.from_4_byte_ascii("#{s}\0")
                   end)

    defwasm imports: [env: [buffer: memory(1)]], exported_globals: [input_offset: i32(1024)] do
      func parse(), result: I32, locals: [i: I32] do
        # If does no end in nul byte, return 0
        if memory32_8![I32.add(input_offset, 3)].unsigned do
          return(0)
        end

        # Write nul byte at end
        memory32_8![I32.add(input_offset, 3)] = 0
        i = memory32![input_offset]

        # Check equality to each weekday as a i32 e.g. `Mon\0`
        inline for {day_i32!, index!} <- Enum.with_index(@weekdays_i32, 1) do
          if I32.eq(i, day_i32!), do: return(index!)
        end

        0
      end
    end

    def set_input(instance, string),
      do: Wasm.instance_write_string_nul_terminated(instance, :input_offset, string)

    def parse(instance), do: Wasm.instance_call(instance, "parse")
  end

  defmodule ContentTypeLookup do
    use Wasm

    @page_size 64 * 1024
    @readonly_start 0xFF
    @bump_start 1 * @page_size
    @input_offset 1 * @page_size
    @output_offset 2 * @page_size
    @strings pack_strings_nul_terminated(@readonly_start,
               charset_utf8: ~S[; charset=utf-8],
               text_plain: ~S[text/plain],
               text_html: ~S[text/html],
               application_json: ~S[application/json],
               application_wasm: ~S[application/wasm],
               image_png: ~S[image/png]
             )

    defwasm imports: [env: [buffer: memory(2)]],
            # exported_globals: [input_offset: i32(1024)],
            globals: [chunk1: i32(0), chunk2: i32(0)] do
      func txt do
        chunk1 = @strings.text_plain.offset
        chunk2 = @strings.charset_utf8.offset
      end

      func html do
        chunk1 = @strings.text_html.offset
        chunk2 = @strings.charset_utf8.offset
      end

      func json do
        chunk1 = @strings.application_json.offset
        chunk2 = @strings.charset_utf8.offset
      end

      func wasm do
        chunk1 = @strings.application_wasm.offset
        chunk2 = 0x0
      end

      func png do
        chunk1 = @strings.image_png.offset
        chunk2 = 0x0
      end
    end

    # def set_input(instance, string),
    #   do: Wasm.instance_write_string_nul_terminated(instance, :input_offset, string)

    # def parse(instance), do: Wasm.instance_call(instance, "parse")
  end

  defmodule HTTPProxy do
    use Wasm

    @page_size 64 * 1024
    @readonly_start 0xFF
    @bump_start 1 * @page_size
    @input_offset 1 * @page_size
    @output_offset 2 * @page_size

    defwasm imports: [
              env: [buffer: memory(3)],
              http: [
                get: func(name: :http_get, params: I32, result: I32)
              ]
            ],
            exported_globals: [
              # memory: memory(3),
              input_offset: i32(@input_offset)
            ] do
      func get_status(), result: I32 do
        # 500
        call(:http_get, 0)
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
        #   func get(address(I32)), result: I32 do
        #     200
        #   end
        # ]

        # http: [
        #   get: fn _address ->
        #     200
        #   end
        # ]
      ]

      ComponentsGuide.Wasm.run_instance(__MODULE__, imports)
    end
  end

  defmodule WebPageIntegrationTest do
    use Wasm

    defwasm imports: [
      navigate: [
        visit: func(name: :visit, params: I32, result: I32)
      ],
      query: [
        get_by_role: func(name: :get_by_role, params: I32, result: I32),
        expect_by_role: func(name: :get_by_role, params: I32),
      ]
    ] do
      func test_home_page, result: I32 do
        # imports.visit("/")
        # imports.expect_by_role("link", "Home")
        call(:visit, const("/"))
        call(:expect_by_role, const("link"), const("Home"))
      end
    end
  end

  defmodule TailwindLike do
    use Wasm

    defwasm imports: [
      navigate: [
        visit: func(name: :visit, params: I32, result: I32)
      ],
      query: [
        get_by_role: func(name: :get_by_role, params: I32, result: I32),
        expect_by_role: func(name: :get_by_role, params: I32),
      ]
    ] do
      func test_home_page, result: I32.String do
        # imports.visit("/")
        # imports.expect_by_role("link", "Home")
        _html = const(~s[<button class="text-lg">Click me</button>])
        _css = const_set_insert(:css, ~s[.text-lg{font-size: 125%}])
        # css = const_list_append(:css, ~s[.text-lg{font-size: 125%}])

        # wind(~s[<button class="text-lg">Click me</button>])
      end
    end
  end

  defmodule FormState do
    use Wasm

    defwasm imports: [

    ] do
      func on_input(input_name(I32), string_value(I32)) do
        # TODO: store string_value under key input_name
        # TODO: add funcs like Keyword.put() to the LinkedLists wasm module
      end

      func on_reset() do

      end

      func to_urlencoded, result: I32 do
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
