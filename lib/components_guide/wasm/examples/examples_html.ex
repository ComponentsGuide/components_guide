defmodule ComponentsGuide.Wasm.Examples.HTML do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
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

      func escape_html, result: I32 do
        call(:escape, 1024, 1024 + 1024)
      end
    end

    def write_input(instance, string) do
      Instance.write_string_nul_terminated(instance, 1024, string)
    end
  end

  defmodule HTMLPage do
    use Wasm

    @request_body_write_offset 65536

    defwasm imports: [
              env: [buffer: memory(2)]
            ],
            # export_memory: memory(2),
            exported_mutable_globals: [
              request_body_write_offset: i32(@request_body_write_offset)
            ],
            globals: [
              body_chunk_index: i32(0)
              # request_body_write_offset: i32(@request_body_write_offset)
            ] do
      func(get_request_body_write_offset, result: I32, do: request_body_write_offset)

      func GET do
        body_chunk_index = 0
      end

      funcp get_is_valid, result: I32 do
        I32.eq(I32.load8_u(request_body_write_offset), ?g)
      end

      func get_status, result: I32 do
        I32.if_else(call(:get_is_valid), do: 200, else: 400)
        # if call(:get_is_valid), result: I32, do: 200, else: 400
      end

      func get_headers, result: I32 do
        const("content-type: text/html;charset=utf-8\\r\\n")
      end

      func next_body_chunk, result: I32 do
        defblock Main, result: I32 do
          if I32.eq(body_chunk_index, 0) do
            const(~S"<!doctype html>")
            break(Main)
          end

          if I32.eq(body_chunk_index, 1) do
            if call(:get_is_valid), result: I32 do
              const("<h1>Good</h1>")
            else
              const("<h1>Bad</h1>")
            end

            break(Main)
          end

          0x0
        end

        body_chunk_index = I32.add(body_chunk_index, 1)
      end
    end

    alias ComponentsGuide.Wasm

    def get_request_body_write_offset(instance) do
      Instance.get_global(instance, :request_body_write_offset)
      # Instance.call(instance, "get_request_body_write_offset")
    end

    def set_request_body_write_offset(instance, offset) do
      Instance.set_global(instance, :request_body_write_offset, offset)
    end

    def write_string_nul_terminated(instance, offset, string) do
      Instance.write_string_nul_terminated(instance, offset, string)
    end

    def set_request_body(instance, body) do
      Instance.write_string_nul_terminated(instance, :request_body_write_offset, body)
    end

    def get(instance) do
      Instance.call(instance, "GET")
    end

    def get_status(instance) do
      Instance.call(instance, :get_status)
    end

    def get_headers(instance) do
      Instance.call_reading_string(instance, :get_headers)
    end

    def next_body_chunk(instance) do
      Instance.call_reading_string(instance, :next_body_chunk)
    end

    def all_body_chunks(instance) do
      Instance.call_stream_string_chunks(instance, :next_body_chunk)
    end

    def read_body(instance) do
      all_body_chunks(instance) |> Enum.join()
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
      func get_current, result: I32, do: count

      func increment, result: I32 do
        count = I32.add(count, 1)
        count
      end

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
            const(~S[<output class="flex p-4 bg-gray-800">])
            branch(Main)
          end

          if I32.eq(body_chunk_index, 1) do
            call(:i32toa, count)
            branch(Main)
          end

          if I32.eq(body_chunk_index, 2) do
            const(~S[</output>])
            branch(Main)
          end

          if I32.eq(body_chunk_index, 3) do
            const(~S[\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>])
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

  defmodule SitemapBuilder do
    use Wasm

    @page_size 64 * 1024
    @readonly_start 0xFFf
    @bump_start 1 * @page_size
    @input_offset 1 * @page_size
    @output_offset 2 * @page_size
    # @output_offset 2 * 64 * 1024

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

      func next_body_chunk, result: I32 do
        defblock Main, result: I32 do
          if I32.eq(body_chunk_index, 0) do
            const(~S[<?xml version="1.0" encoding="UTF-8"?>\n])
            break(Main)
          end

          if I32.eq(body_chunk_index, 1) do
            const(~S[<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n])
            break(Main)
          end

          if I32.eq(body_chunk_index, 2) do
            const(~S[<url>\n])
            break(Main)
          end

          if I32.eq(body_chunk_index, 3) do
            const(~S[<loc>])
            break(Main)
          end

          if I32.eq(body_chunk_index, 4) do
            # call(:escape, read_offset: input_offset, write_offset: output_offset)
            call(:escape, input_offset, output_offset)
            push(output_offset)

            break(Main)
          end

          if I32.eq(body_chunk_index, 5) do
            const(~S[</loc>\n])
            break(Main)
          end

          if I32.eq(body_chunk_index, 6) do
            const(~S[</url>\n])
            break(Main)
          end

          if I32.eq(body_chunk_index, 7) do
            const(~S[</urlset>\n])
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
end
