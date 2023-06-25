defmodule ComponentsGuide.Wasm.Examples.HTML do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.LinkedLists

  defmodule EscapeHTML do
    use Wasm

    @wasm_memory 2

    @escaped_html_table [
      {?&, ~C"&amp;"},
      {?<, ~C"&lt;"},
      {?>, ~C"&gt;"},
      {?", ~C"&quot;"},
      {?', ~C"&#39;"}
    ]

    defwasm do
      funcp escape(read_offset(I32), write_offset(I32)),
            I32,
            char: I32,
            bytes_written: I32 do
        bytes_written = 0

        loop EachChar, result: I32 do
          defblock Outer do
            char = memory32_8![read_offset].unsigned

            inline for {char_to_match!, chars_out!} <- ^@escaped_html_table do
              if I32.eq(char, ^char_to_match!) do
                inline for char_out! <- ^chars_out! do
                  memory32_8![I32.add(write_offset, bytes_written)] = ^char_out!
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
          EachChar.continue()
        end
      end

      func escape_html(), I32 do
        call(:escape, 1024, 1024 + 1024)
      end
    end

    def write_input(instance, string) do
      Instance.write_string_nul_terminated(instance, 1024, string)
    end
  end

  defmodule HTMLPage do
    use Wasm

    @wasm_memory 2
    @request_body_write_offset 65536

    defwasm exported_mutable_globals: [
              request_body_write_offset: i32(@request_body_write_offset)
            ],
            globals: [
              body_chunk_index: i32(0)
              # request_body_write_offset: i32(@request_body_write_offset)
            ] do
      func(get_request_body_write_offset(), I32, do: request_body_write_offset)

      func GET do
        body_chunk_index = 0
      end

      funcp get_is_valid(), I32 do
        I32.eq(I32.load8_u(request_body_write_offset), ?g)
      end

      func get_status(), I32 do
        I32.when?(call(:get_is_valid), do: 200, else: 400)
        # if call(:get_is_valid), result: I32, do: 200, else: 400
      end

      func get_headers(), I32 do
        const("content-type: text/html;charset=utf-8\\r\\n")
      end

      func next_body_chunk(), I32 do
        I32.match body_chunk_index do
          0 ->
            ~S"<!doctype html>"

          1 ->
            if call(:get_is_valid), result: I32 do
              const("<h1>Good</h1>")
            else
              const("<h1>Bad</h1>")
            end

          _ ->
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
    use Orb
    use BumpAllocator

    # @body deftemplate(~E"""
    #       <output class="flex p-4 bg-gray-800"><%= call(:i32toa, count) %></output>
    #       <button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>
    #       """)

    @wasm_memory 1

    global(
      count: i32(0),
      body_chunk_index: i32(0)
    )

    wasm do
      func(get_current(), I32, do: @count)

      func increment, I32 do
        @count = I32.add(@count, 1)
        @count
      end

      func rewind, nil, i: I32 do
        @body_chunk_index = 0
        @bump_offset = BumpAllocator.Constants.bump_init_offset()

        i = 64

        loop Clear do
          memory32![I32.add(i, BumpAllocator.Constants.bump_init_offset())] = 0x0

          if I32.gt_u(i, 0) do
            i = I32.sub(i, 1)
            Clear.continue()
          end
        end
      end

      funcp i32toa(value(I32)), I32, working_offset: I32, digit: I32 do
        # Max int is 4294967296 which has 10 digits. We add one for nul byte.
        # We “allocate” all 11 bytes upfront to make the algorithm easier.
        @bump_offset = I32.u!(@bump_offset + 11)
        # We then start from the back, as we have to print the digits in reverse.
        working_offset = @bump_offset

        loop Digits do
          working_offset = I32.u!(working_offset - 1)

          digit = I32.rem_u(value, 10)
          value = I32.u!(value / 10)
          memory32_8![working_offset] = I32.u!(?0 + digit)

          Digits.continue(if: I32.u!(value > 0))
        end

        working_offset
      end

      func next_body_chunk, I32 do
        I32.match @body_chunk_index do
          0 ->
            ~S[<output class="flex p-4 bg-gray-800">]

          1 ->
            call(:i32toa, @count)

          2 ->
            ~S[</output>]

          3 ->
            ~S[\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]

          _ ->
            0x0
        end

        @body_chunk_index = I32.u!(@body_chunk_index + 1)
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

    def start(), do: Instance.run(__MODULE__)
    def exports(), do: Wasm.list_exports(__MODULE__)

    def initial_html() do
      instance = start()
      read_body(instance)
    end
  end

  defmodule SitemapBuilder do
    use Wasm
    use BumpAllocator
    use LinkedLists

    @wasm_memory 3

    @page_size 64 * 1024
    @_bump_start 1 * @page_size
    @input_offset 1 * @page_size
    @_output_offset 2 * @page_size
    # @_output_offset 2 * 64 * 1024

    global(:export_readonly,
      input_offset: i32(@_bump_start)
    )

    global(
      body_chunk_index: i32(0),
      output_offset: i32(@_output_offset),
      url_list: i32(0x0)
    )

    wasm do
      # funcp escape_html, I32, globals: [body_chunk_index: I32], source: EscapeHTML

      # EscapeHTML.funcp(escape, I32)
      # EscapeHTML.funcp escape(read_offset(I32), write_offset(I32)), I32
      EscapeHTML.funcp(:escape)

      func(alloc(byte_size(I32)), I32, do: call(:bump_alloc, byte_size))

      func rewind do
        @body_chunk_index = 0
      end

      func free(), nil, i: I32 do
        @bump_offset = BumpAllocator.Constants.bump_init_offset()

        # for (i = 64, i >= 0; i--)
        i = 64

        # loop Clear, 64..0//-1 do
        # loop Clear, 0..64 do
        # loop 0, 64, -1, i do
        # i.loop 0, 64, -1 do
        # while I32.ge_u(i, 0) do
        # loop Clear, while: I32.ge_u(i, 0) do
        loop Clear do
          memory32![I32.add(i, BumpAllocator.Constants.bump_init_offset())] = 0x0

          if I32.gt_u(i, 0) do
            i = I32.sub(i, 1)
            Clear.continue()
          end
        end
      end

      func add_url(str_ptr(I32)) do
        @url_list = call(:cons, str_ptr, @url_list)
      end

      func next_body_chunk, I32 do
        I32.match @body_chunk_index do
          0 ->
            @url_list = call(:reverse_in_place, @url_list)
            @body_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)

            ~S"""
            <?xml version="1.0" encoding="UTF-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            """

            return()

          1 ->
            ~S"<url>\n<loc>"

          2 ->
            call(:escape, call(:hd, @url_list), @output_offset)
            push(@output_offset)

          3 ->
            @url_list = call(:tl, @url_list)
            @body_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)

            ~S"""
            </loc>
            </url>
            """

            # if @url_list do
            #   @body_chunk_index = 1
            #   return()
            # end

            return()

          4 ->
            ~S"""
            </urlset>
            """

          _ ->
            0x0
        end

        @body_chunk_index = I32.add(@body_chunk_index, 1)
      end
    end

    def write_input(instance, string) do
      # Instance.alloc_string(instance, string)

      Instance.write_string_nul_terminated(instance, :input_offset, string)
    end

    def read_body(instance) do
      Instance.call(instance, "rewind")
      Instance.call_stream_string_chunks(instance, "next_body_chunk") |> Enum.join()
    end
  end

  defmodule HTMLFormBuilder do
    use Wasm
    use BumpAllocator
    use LinkedLists

    @wasm_memory 3

    @_field_types I32.calculate_enum([
                    :textbox,
                    :url,
                    :email,
                    :checkbox,
                    :hidden
                  ])

    # @textbox_tuple Tuple.define(name: I32, label: I32)

    global(
      body_chunk_index: i32(0),
      form_element_list: i32(0x0)
    )

    # wasm_import(
    #   log: [
    #     int32: func(name: :log32, params: I32, result: I32)
    #   ]
    # )

    defwasm imports: [
              log: [
                int32: func(name: :log32, params: I32, result: I32)
              ]
            ] do
      # funcp escape_html, result: I32, globals: [body_chunk_index: I32], source: EscapeHTML
      EscapeHTML.funcp(:escape)
      LinkedLists.funcp(:cons)
      LinkedLists.funcp(:hd)
      LinkedLists.funcp(:tl)
      LinkedLists.funcp(:reverse_in_place)

      func(alloc(byte_size(I32)), I32, do: call(:bump_alloc, byte_size))

      func add_textbox(name_ptr(I32)) do
        @form_element_list = call(:cons, name_ptr, @form_element_list)
      end

      func rewind() do
        @body_chunk_index = 0
      end

      func next_body_chunk, I32 do
        I32.match @body_chunk_index do
          0 ->
            @form_element_list = call(:reverse_in_place, @form_element_list)
            @body_chunk_index = @form_element_list |> I32.eqz?(do: 6, else: 1)

            ~S[<form>\n]
            return()

          1 ->
            ~S[<label for="]

          2 ->
            call(:hd, @form_element_list)

          3 ->
            ~S[">\n  <input type="text" name="]

          4 ->
            call(:hd, @form_element_list)

          5 ->
            @form_element_list = call(:tl, @form_element_list)
            @body_chunk_index = @form_element_list |> I32.eqz?(do: 6, else: 1)

            ~S[">\n</label>\n]

            # if @form_element_list do
            #   @body_chunk_index = 1
            #   return()
            # end

            return()

          6 ->
            ~S[</form>\n]

          _ ->
            0x0
        end

        @body_chunk_index = I32.add(@body_chunk_index, 1)
      end
    end

    def read_body(instance) do
      Instance.call_joining_string_chunks(instance, :next_body_chunk)
    end

    def start() do
      imports = [
        {:log, :int32,
         fn value ->
           IO.inspect(value, label: "wasm log int32")
           0
         end}
      ]

      ComponentsGuide.Wasm.run_instance(__MODULE__, imports)
    end
  end
end
