defmodule ComponentsGuide.Wasm.Examples do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

  defmodule EscapeHTML do
    use Wasm

    @escaped_html_table [
      {?&, ~C"&amp;"},
      {?<, ~C"&lt;"},
      {?>, ~C"&gt;"},
      {?", ~C"&quot;"},
      {?', ~C"&#39;"}
    ]

    defwasm imports: [env: [buffer: memory(2)]] do
      funcp escape(read_offset(I32), write_offset(I32)),
        result: I32,
        locals: [char: I32, bytes_written: I32] do
        bytes_written = 0

        defloop EachChar, result: I32 do
          defblock Outer do
            char = memory32_8![read_offset].unsigned

            inline for {char_to_match!, chars_out!} <- @escaped_html_table do
              if I32.eq(char, char_to_match!) do
                inline for char_out! <- chars_out! do
                  memory32_8![I32.add(write_offset, bytes_written)] = char_out!
                  bytes_written = I32.add(bytes_written, 1)
                end

                break(Outer)
              end
            end

            memory32_8![I32.add(write_offset, bytes_written)] = char

            if char do
              bytes_written = I32.add(bytes_written, 1)
              break(Outer)
            else
              push(bytes_written)
              return()
            end
          end

          read_offset = I32.add(read_offset, 1)
          # continue(EachChar)
          # halt(EachChar)
          # :continue
          # EachChar
          branch(EachChar)
        end
      end

      func escape_html, result: I32, locals: [read_offset: I32, write_offset: I32, char: I32] do
        call(:escape, 1024, 1024 + 1024)
      end
    end

    def write_input(instance, string) do
      Wasm.instance_write_string_nul_terminated(instance, 1024, string)
    end
  end

  defmodule HTMLPage do
    use Wasm

    @strings pack_strings_nul_terminated(4,
               doctype: "<!doctype html>",
               good: "<h1>Good</h1>",
               bad: "<h1>Bad</h1>",
               content_type: "content-type: text/html;charset=utf-8\\r\\n"
             )

    # Doesn’t work because we are evaluating the block at compile time.
    def doctype do
      4
    end

    @request_body_write_offset 65536

    defwasm imports: [
              env: [buffer: memory(2)]
            ],
            exported_globals: [
              request_body_write_offset: i32(@request_body_write_offset)
            ],
            globals: [
              body_chunk_index: i32(0)
              # request_body_write_offset: i32(@request_body_write_offset)
            ] do
      data_nul_terminated(@strings)

      func get_request_body_write_offset, result: I32 do
        request_body_write_offset
      end

      func GET do
        body_chunk_index = 0
      end

      funcp get_is_valid, result: I32 do
        I32.eq(I32.load8_u(request_body_write_offset), ?g)
      end

      func get_status, result: I32 do
        # I32.if_else(call(:get_is_valid), do: 200, else: 400)
        I32.if_else call(:get_is_valid) do
          200
        else
          400
        end

        # if call(:get_is_valid) do
        #   return(200)
        # else
        #   return(400)
        # end
      end

      func get_headers, result: I32 do
        @strings.content_type.offset
      end

      func next_body_chunk, result: I32, locals: [is_valid: I32] do
        is_valid = call(:get_is_valid)
        body_chunk_index = I32.add(body_chunk_index, 1)

        # I32.if_else(I32.eq(body_chunk_index, 1),
        #   do: 4,
        #   else: I32.if_else(is_valid, do: 20, else: 40)
        # )
        # I32.if_else(I32.eq(body_chunk_index, 1),
        #   do: lookup_data(:doctype),
        #   else: I32.if_else(is_valid, do: lookup_data(:good_heading), else: lookup_data(:bad_heading))
        # )

        # br_table do
        #   1 -> 4
        #   2 ->
        #     if is_valid do
        #       @strings.good.offset
        #     else
        #       @strings.bad.offset
        #     end
        #   _ -> 0
        # end

        # I32.if_else I32.eq(body_chunk_index, 1), do: return(4)
        # I32.if_else I32.eq(body_chunk_index, 2), do: return(@strings.good.offset)
        # 0

        # if I32.eq(body_chunk_index, 1) do
        #   return(@strings.doctype.offset)
        #   # :return
        # end

        # if I32.eq(body_chunk_index, 2) do
        #   @strings.good.offset
        #   # if is_valid do
        #   #   push(@strings.good.offset)
        #   # else
        #   #   push(@strings.bad.offset)
        #   # end
        # else
        #   push(0)
        # end

        I32.if_else(I32.eq(body_chunk_index, 1),
          do: @strings.doctype.offset,
          else:
            I32.if_else(I32.eq(body_chunk_index, 2),
              do: I32.if_else(is_valid, do: @strings.good.offset, else: @strings.bad.offset),
              else: 0
            )
        )
      end
    end

    alias ComponentsGuide.Wasm

    def get_request_body_write_offset(instance) do
      Wasm.instance_get_global(instance, "request_body_write_offset")
      # Wasm.instance_call(instance, "get_request_body_write_offset")
    end

    def set_request_body_write_offset(instance, offset) do
      Wasm.instance_set_global(instance, "request_body_write_offset", offset)
    end

    def write_string_nul_terminated(instance, offset, string) do
      Wasm.instance_write_string_nul_terminated(instance, offset, string)
    end

    def set_request_body(instance, body) do
      Wasm.instance_write_string_nul_terminated(instance, :request_body_write_offset, body)
    end

    def get(instance) do
      Wasm.instance_call(instance, "GET")
    end

    def get_status(instance) do
      Wasm.instance_call(instance, "get_status")
    end

    def get_headers(instance) do
      Wasm.instance_call_returning_string(instance, "get_headers")
    end

    def next_body_chunk(instance) do
      Wasm.instance_call_returning_string(instance, "next_body_chunk")
    end

    def all_body_chunks(instance) do
      Stream.unfold(0, fn n ->
        case Wasm.instance_call_returning_string(instance, "next_body_chunk") do
          "" -> nil
          s -> {s, n + 1}
        end
      end)
    end

    def read_body(instance) do
      all_body_chunks(instance) |> Enum.join()
    end
  end

  defmodule Counter do
    use Wasm

    defwasm imports: [
              env: [buffer: memory(1)]
            ],
            globals: [
              count: i32(0)
            ] do
      func get_current, result: I32 do
        count
      end

      func increment, result: I32 do
        count = I32.add(count, 1)
        count
      end
    end

    alias ComponentsGuide.Wasm

    def get_current(instance) do
      Wasm.instance_call(instance, "get_current")
    end

    def increment(instance) do
      Wasm.instance_call(instance, "increment")
    end
  end

  # defmodule CounterHTMLFuture do
  #   defcomponent state: [
  #     count: 0
  #   ] do
  #     render do
  #       ~E"""
  #       <output><%= @count %></output>
  #       <button data-action="increment">Increment</button>
  #       """
  #     end

  #     action increment do
  #       %{count: count + 1}
  #       # count = count + 1
  #     end
  #   end
  # end

  defmodule CounterHTML do
    use Wasm

    @strings pack_strings_nul_terminated(0x4,
               output_start: ~S[<output class="flex p-4 bg-gray-800">],
               output_end: ~S[</output>],
               button_increment:
                 ~S[\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]
             )

    # @body deftemplate(~E"""
    #       <output class="flex p-4 bg-gray-800"><%= call(:i32toa, count) %></output>
    #       <button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>
    #       """)

    @bump_start 1024

    defwasm imports: [
              env: [buffer: memory(1)]
            ],
            globals: [
              count: i32(0),
              body_chunk_index: i32(0),
              bump_offset: i32(@bump_start)
            ] do
      func get_current, result: I32 do
        count
      end

      func increment, result: I32 do
        count = I32.add(count, 1)
        count
      end

      data_nul_terminated(@strings)

      func rewind, locals: [i: I32] do
        body_chunk_index = 0
        bump_offset = @bump_start

        i = 64

        defloop Clear do
          memory32![I32.add(i, @bump_start)] = 0x0

          if I32.gt_u(i, 0) do
            i = I32.sub(i, 1)
            branch(Clear)
          end
        end
      end

      funcp i32toa(value(I32)), result: I32, locals: [working_offset: I32, digit: I32] do
        # Max int is 4294967296 which has 10 digits. We add one for nul byte.
        # We “allocate” all 11 bytes upfront to make the algorithm easier.
        bump_offset = I32.add(bump_offset, 11)
        # We then start from the back, as we have to print the digits in reverse.
        working_offset = bump_offset

        defloop Digits do
          working_offset = I32.sub(working_offset, 1)

          digit = I32.rem_u(value, 10)
          value = I32.div_u(value, 10)
          memory32_8![working_offset] = I32.add(?0, digit)

          branch(Digits, if: I32.gt_u(value, 0))
        end

        working_offset
      end

      func next_body_chunk, result: I32 do
        defblock Main, result: I32 do
          if I32.eq(body_chunk_index, 0) do
            push(@strings.output_start.offset)
            branch(Main)
          end

          if I32.eq(body_chunk_index, 1) do
            call(:i32toa, count)
            branch(Main)
          end

          if I32.eq(body_chunk_index, 2) do
            push(@strings.output_end.offset)
            branch(Main)
          end

          if I32.eq(body_chunk_index, 3) do
            push(@strings.button_increment.offset)
            branch(Main)
          end

          0x0
        end

        body_chunk_index = I32.add(body_chunk_index, 1)
      end
    end

    alias ComponentsGuide.Wasm

    def get_current(instance) do
      Wasm.instance_call(instance, "get_current")
    end

    def increment(instance) do
      Wasm.instance_call(instance, "increment")
    end

    def read_body(instance) do
      Wasm.instance_call(instance, "rewind")
      Wasm.instance_call_stream_string_chunks(instance, "next_body_chunk") |> Enum.join()
    end

    def initial_html() do
      instance = start()
      read_body(instance)
    end
  end

  defmodule Loader do
    use Wasm

    # defmodule LoadableMachine do
    #   use Machine,
    #     states: [:idle, :loading, :loaded, :failed]

    # defstate Idle do
    #   on(:start), do: Loading
    # end

    #   def on(:idle, :start), do: :loading
    #   def entry(:loading), do: :load
    #   def on(:loading, :success), do: :loaded
    #   def on(:loading, :failure), do: :failed
    # end

    defwasm imports: [
              # env: [buffer: memory(1)]
            ],
            exported_globals: [
              idle: i32(0),
              loading: i32(1),
              loaded: i32(2),
              failed: i32(3)
            ],
            globals: [
              state: i32(0)
            ] do
      # func get_current, do: state
      func get_current, result: I32 do
        state
      end

      # defstates :state do
      #   state Idle do
      #     :begin -> Loading
      #   end

      #   state Loading do
      #     :success -> Loaded
      #     :failure -> Failed
      #   end

      #   state Loaded do
      #   end

      #   state Failed do
      #   end
      # end

      func begin do
        if I32.eq(state, idle) do
          state = loading
          # {:raw_wat, ~s[(global.set $state (i32.const 1))]}

          # TODO: Call entry callback “load”
        end
      end

      func success do
        if I32.eq(state, loading) do
          state = loaded
        end
      end

      func failure do
        if I32.eq(state, loading) do
          state = failed
        end
      end
    end

    alias ComponentsGuide.Wasm

    def get_current(instance), do: Wasm.instance_call(instance, "get_current")
    def begin(instance), do: Wasm.instance_call(instance, "begin")
    def success(instance), do: Wasm.instance_call(instance, "success")
    def failure(instance), do: Wasm.instance_call(instance, "failure")
  end

  defmodule SitemapBuilder do
    use Wasm

    @page_size 64 * 1024
    @readonly_start 0xFF
    @bump_start 1 * @page_size
    @input_offset 1 * @page_size
    @output_offset 2 * @page_size
    # @output_offset 2 * 64 * 1024

    @strings pack_strings_nul_terminated(@readonly_start,
               xml_declaration: ~S[<?xml version="1.0" encoding="UTF-8"?>\n],
               urlset_start: ~S[<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n],
               urlset_end: ~S[</urlset>\n],
               url_start: ~S[<url>\n],
               url_end: ~S[</url>\n],
               loc_start: ~S[<loc>],
               loc_end: ~S[</loc>\n]
             )

    @escaped_html_table [
      {?&, ~C"&amp;"},
      {?<, ~C"&lt;"}
    ]

    defwasm imports: [
              env: [buffer: memory(3)]
            ],
            exported_globals: [
              input_offset: i32(@bump_start)
            ],
            globals: [
              body_chunk_index: i32(0),
              bump_offset: i32(@bump_start),
              output_offset: i32(@output_offset)
            ] do
      # func escape_html, result: I32, from: StringHelpers
      # funcp escape_html, result: I32, globals: [body_chunk_index: I32], source: EscapeHTML

      # cpfuncp EscapeHTML, escape
      # cpfuncp escape(read_offset(I32), write_offset(I32)),from: EscapeHTML, result: I32)
      # EscapeHTML.cpfuncp(escape, result: I32)
      # EscapeHTML.cpfuncp escape(read_offset(I32), write_offset(I32)),from: EscapeHTML, result: I32)
      cpfuncp(escape, from: EscapeHTML, result: I32)

      cpfuncp(bump_alloc, from: BumpAllocator, result: I32)
      cpfuncp(bump_free_all, from: BumpAllocator, result: I32)

      func alloc_bytes(byte_size(I32)), result: I32 do
        # Need better maths than this
        call(:bump_alloc, byte_size)
      end

      func rewind do
        body_chunk_index = 0
      end

      func free, locals: [i: I32] do
        bump_offset = @bump_start

        # for (i = 64, i >= 0; i--)
        i = 64

        # defloop Clear, 64..0//-1 do
        # defloop Clear, 0..64 do
        # defloop 0, 64, -1, i do
        # i.loop 0, 64, -1 do
        # while I32.ge_u(i, 0) do
        # loop Clear, while: I32.ge_u(i, 0) do
        defloop Clear do
          memory32![I32.add(i, @bump_start)] = 0x0

          if I32.gt_u(i, 0) do
            i = I32.sub(i, 1)
            branch(Clear)
          end
        end
      end

      # func next_body_chunk, ~E"""
      # <?xml version="1.0" encoding="UTF-8"?>
      # <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      # <url>
      # <loc>
      #   <% call(:escape, input_offset, output_offset) %>
      #   <%= output_offset %>
      # </loc>
      # </url>
      # </urlset>
      # """

      data_nul_terminated(@strings)

      func next_body_chunk, result: I32 do
        defblock Main, result: I32 do
          # if I32.eq(body_chunk_index, 0), return: @strings.xml_declaration.offset

          if I32.eq(body_chunk_index, 0) do
            # return(@strings.xml_declaration.offset)
            push(@strings.xml_declaration.offset)
            break(Main)
          end

          if I32.eq(body_chunk_index, 1) do
            push(@strings.urlset_start.offset)
            break(Main)
          end

          if I32.eq(body_chunk_index, 2) do
            push(@strings.url_start.offset)
            break(Main)
          end

          if I32.eq(body_chunk_index, 3) do
            push(@strings.loc_start.offset)
            break(Main)
          end

          if I32.eq(body_chunk_index, 4) do
            # call(:escape, read_offset: input_offset, write_offset: output_offset)
            call(:escape, input_offset, output_offset)
            push(output_offset)

            break(Main)
          end

          if I32.eq(body_chunk_index, 5) do
            push(@strings.loc_end.offset)
            break(Main)
          end

          if I32.eq(body_chunk_index, 6) do
            push(@strings.url_end.offset)
            break(Main)
          end

          if I32.eq(body_chunk_index, 7) do
            push(@strings.urlset_end.offset)
            break(Main)
          end

          0x0
        end

        body_chunk_index = I32.add(body_chunk_index, 1)
      end
    end

    def write_input(instance, string) do
      # address = Wasm.instance_call(instance, :alloc, byte_size(string))
      # Wasm.instance_write_string_nul_terminated(instance, address, string)

      Wasm.instance_write_string_nul_terminated(instance, :input_offset, string)
    end

    def read_body(instance) do
      Wasm.instance_call(instance, "rewind")
      Wasm.instance_call_stream_string_chunks(instance, "next_body_chunk") |> Enum.join()
      # Wasm.instance_call_returning_string(instance, "next_body_chunk")
    end
  end

  defmodule LamportClock do
    use Wasm

    defwasm exported_globals: [time: i32(0)] do
      func will_send(), result: I32 do
        time = I32.add(time, 1)
        time
      end

      func received(incoming_time(I32)), result: I32 do
        if I32.gt_u(incoming_time, time) do
          time = incoming_time
        end

        time = I32.add(time, 1)
        time
      end
    end

    def read(instance) do
      Wasm.instance_get_global(instance, :time)
    end

    def will_send(instance) do
      Wasm.instance_call(instance, "will_send")
    end

    def send(a, b) do
      t = will_send(a)
      received(b, t)
    end

    def received(instance, incoming_time) do
      Wasm.instance_call(instance, "received", incoming_time)
    end
  end

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
              # http_get: func http_get(I32),
              http: [
                get: func(name: :http_get, params: I32, result: I32)
              ]
            ],
            exported_globals: [
              input_offset: i32(@input_offset)
            ] do
      func get_status(), result: I32 do
        # 500
        call(:http_get, 0)
      end
    end

    def start(_init) do
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

  defmodule Base64Encode do
  end

  defmodule GzipCompress do
  end

  defmodule URLParser do
    # Lets you extract out host, path, query params.
  end
end