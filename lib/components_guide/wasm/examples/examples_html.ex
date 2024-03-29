defmodule ComponentsGuide.Wasm.Examples.HTML do
  alias OrbWasmtime.{Instance, Wasm}
  alias ComponentsGuide.Wasm.Examples.StringBuilder
  alias ComponentsGuide.Wasm.Examples.Memory.LinkedLists

  defmodule BuildHTML do
    use Orb
    use SilverOrb.BumpAllocator
    use StringBuilder

    Memory.pages(2)

    @escaped_html_table [
      {?&, ~C"&amp;"},
      {?<, ~C"&lt;"},
      {?>, ~C"&gt;"},
      {?", ~C"&quot;"},
      {?', ~C"&#39;"}
    ]

    Orb.__append_body U32 do
      funcp append_char_html_escaped(char: I32.U8) do
        inline for {char_to_match!, chars_out!} <- @escaped_html_table do
          if I32.eq(char, char_to_match!) do
            inline for char_out! <- chars_out! do
              append!(u8: char_out!)
            end

            return()
          end
        end

        append!(u8: char)
      end
    end

    def append_html_escaped!(char: char) do
      Orb.DSL.typed_call(:unknown_effect, :append_char_html_escaped, char)
    end

    defmacro __using__(_) do
      quote do
        import unquote(__MODULE__)

        Orb.__append_body do
          unquote(__MODULE__).funcp()
        end
      end
    end
  end

  defmodule EscapeHTML do
    use Orb
    use SilverOrb.BumpAllocator

    Memory.pages(2)

    @escaped_html_table [
      {?&, ~C"&amp;"},
      {?<, ~C"&lt;"},
      {?>, ~C"&gt;"},
      {?", ~C"&quot;"},
      {?', ~C"&#39;"}
    ]

    Orb.__append_body U32 do
      funcp escape(read_offset: I32.U8.UnsafePointer, write_offset: I32.U8.UnsafePointer),
            I32,
            char: I32.U8,
            bytes_written: I32 do
        bytes_written = 0

        # I32.U8.consume_chars read_offset, char do
        # end

        loop EachChar, result: I32 do
          char = read_offset[at!: 0]
          read_offset = read_offset + 1

          inline for {char_to_match!, chars_out!} <- @escaped_html_table do
            wasm do
              if I32.eq(char, char_to_match!) do
                inline for char_out! <- chars_out! do
                  wasm do
                    write_offset[at!: bytes_written] = char_out!
                    bytes_written = bytes_written + 1
                  end
                end

                EachChar.continue()
              end
            end
          end

          write_offset[at!: bytes_written] = char

          if char do
            bytes_written = bytes_written + 1
            EachChar.continue()
          else
            push(bytes_written)
            return()
          end

          EachChar.continue()
        end
      end

      func escape_html(), I32 do
        typed_call(I32, :escape, [1024, 1024 + 1024])
      end
    end

    def write_input(instance, string) do
      Instance.write_string_nul_terminated(instance, 1024, string)
    end
  end

  defmodule HTMLPage do
    use Orb

    Memory.pages(2)
    @request_body_write_offset 65536

    I32.global(body_chunk_index: 0)
    I32.export_global(:mutable, request_body_write_offset: @request_body_write_offset)

    Orb.__append_body U32 do
      func(get_request_body_write_offset(), I32, do: @request_body_write_offset)

      func GET do
        @body_chunk_index = 0
      end

      funcp get_is_valid(), I32 do
        I32.eq(Memory.load!(I32.U8, @request_body_write_offset), ?g)
      end

      func get_status(), I32 do
        I32.when?(typed_call(I32, :get_is_valid, []), do: 200, else: 400)
      end

      func get_headers(), I32 do
        ~S"content-type: text/html;charset=utf-8\r\n"
      end

      func next_body_chunk(), I32 do
        I32.match @body_chunk_index do
          0 ->
            ~S"<!doctype html>"

          1 ->
            if typed_call(I32, :get_is_valid, []), result: I32 do
              ~S"<h1>Good</h1>"
            else
              ~S"<h1>Bad</h1>"
            end

          _ ->
            0x0
        end

        @body_chunk_index = @body_chunk_index + 1
      end
    end

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
    use SilverOrb.BumpAllocator

    # @body deftemplate(~E"""
    #       <output class="flex p-4 bg-gray-800"><%= call(:i32toa, count) %></output>
    #       <button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>
    #       """)

    Memory.pages(1)

    I32.global(
      count: 0,
      body_chunk_index: 0
    )

    Orb.__append_body do
      func(get_current(), I32, do: @count)

      func increment(), I32 do
        @count = I32.add(@count, 1)
        @count
      end

      func rewind(), ptr: I32.UnsafePointer do
        @body_chunk_index = 0
        @bump_offset = SilverOrb.BumpAllocator.Constants.bump_init_offset()

        ptr = I32.add(64, @bump_offset)

        loop Clear do
          ptr[at!: 0] = 0x0

          if I32.gt_u(ptr, @bump_offset) do
            ptr = I32.sub(ptr, 1)
            Clear.continue()
          end
        end
      end

      #     end
      #
      #     Orb.__append_body do
      funcp i32toa(value: I32), I32, working_ptr: I32.U8.UnsafePointer, digit: I32 do
        # Max int is 4294967296 which has 10 digits. We add one for nul byte.
        # We “allocate” all 11 bytes upfront to make the algorithm easier.
        @bump_offset = @bump_offset + 11
        # We then start from the back, as we have to print the digits in reverse.
        working_ptr = @bump_offset

        loop Digits do
          working_ptr = working_ptr - 1

          digit = I32.rem_u(value, 10)
          value = value / 10
          working_ptr[at!: 0] = ?0 + digit

          Digits.continue(if: value > 0)
        end

        working_ptr
      end

      func next_body_chunk, I32 do
        I32.match @body_chunk_index do
          0 ->
            ~S[<output class="flex p-4 bg-gray-800">]

          1 ->
            typed_call(I32, :i32toa, [@count])

          2 ->
            ~S[</output>]

          3 ->
            ~S[\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]

          _ ->
            0x0
        end

        @body_chunk_index = @body_chunk_index + 1
      end
    end

    def get_current(instance) do
      Instance.call(instance, "get_current")
    end

    def increment(instance) do
      Instance.call(instance, "increment")
    end

    def read_body(instance) do
      Instance.call(instance, "rewind")
      Instance.call_joining_string_chunks(instance, "next_body_chunk")
    end

    def start(), do: Instance.run(__MODULE__)
    def exports(), do: Wasm.list_exports(__MODULE__)

    def initial_html() do
      instance = start()
      read_body(instance)
    end
  end

  defmodule MultiStepForm do
    # See: https://buildui.com/courses/framer-motion-recipes/multistep-wizard

    use Orb
    use SilverOrb.BumpAllocator
    use I32.String
    use StringBuilder

    I32.export_global(:mutable, step_count: 4)
    I32.global(step: 1)

    Orb.__append_body U32 do
      func(get_current_step(), I32, do: @step)

      funcp _change_step(step: I32) do
        I32.cond do
          step < 1 -> 1
          step > @step_count -> @step_count
          true -> step
        end

        @step =
          I32.when? step < 1 do
            1
          else
            I32.when?(step > @step_count, do: @step_count, else: step)
          end
      end

      func(next_step(), do: call(:_change_step, @step + 1))
      func(previous_step(), do: call(:_change_step, @step - 1))
      func(jump_to_step(step: I32), do: call(:_change_step, step))

      func(to_string(), I32.String, do: call(:to_html))

      func to_html(), I32.String do
        build! do
          append!(:build_step, 1)
          append!(:build_step, 2)
          append!(:build_step, 3)
          append!(:build_step, 4)
          append!(:build_step, 5)
        end

        # join!([
        #   call(:build_step, 1),
        #   call(:build_step, 2),
        #   call(:build_step, 3),
        #   call(:build_step, 4),
        #   call(:build_step, 5)
        # ])
      end

      funcp build_step(step: I32), I32.String do
        build! do
          append!(string: ~S[<div class="w-4 h-4 text-center])

          if I32.eq(global_get(:step), step) do
            append!(string: ~S[ bg-blue-600 text-white])
          else
            append!(string: ~S[ text-black])
          end

          append!(string: ~S[">])
          append!(decimal_u32: step)
          append!(string: ~S[</div>\n])
        end
      end
    end
  end

  defmodule SitemapBuilder do
    use Orb
    use SilverOrb.BumpAllocator
    use LinkedLists

    SilverOrb.BumpAllocator.export_alloc()

    Memory.pages(3)

    @page_size 64 * 1024
    @bump_start 1 * @page_size
    @output_offset 2 * @page_size

    I32.export_global(:readonly,
      input_offset: @bump_start
    )

    I32.global(
      body_chunk_index: 0,
      output_offset: @output_offset,
      url_list: 0x0
    )

    Orb.__append_body U32 do
      # EscapeHTML.funcp(escape, I32)
      # EscapeHTML.funcp escape(read_offset: I32, write_offset: I32), I32
      EscapeHTML.funcp(:escape)

      func rewind() do
        @body_chunk_index = 0
      end

      func add_url(str_ptr: I32.U8.UnsafePointer) do
        @url_list = cons(str_ptr, @url_list)
      end

      func next_body_chunk(), I32 do
        I32.match @body_chunk_index do
          0 ->
            reverse_in_place!(mut!(@url_list))
            @body_chunk_index = I32.when?(@url_list === 0, do: 4, else: 1)

            ~S"""
            <?xml version="1.0" encoding="UTF-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            """

            return()

          1 ->
            ~S"<url>\n<loc>"

          2 ->
            call(:escape, hd!(@url_list), @output_offset)
            push(@output_offset)

          3 ->
            @url_list = tl!(@url_list)
            @body_chunk_index = I32.when?(@url_list === 0, do: 4, else: 1)

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

        @body_chunk_index = @body_chunk_index + 1
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
    use Orb
    use SilverOrb.BumpAllocator
    use LinkedLists

    SilverOrb.BumpAllocator.export_alloc()

    # Memory.pages(3)

    # @field_types I32.calculate_enum([
    #                :textbox,
    #                :url,
    #                :email,
    #                :checkbox,
    #                :hidden
    #              ])

    # @textbox_tuple Tuple.define(name: I32, label: I32)

    I32.global(
      body_chunk_index: 0,
      form_element_list: 0x0
    )

    Orb.__append_body U32 do
      EscapeHTML.funcp(:escape)

      func add_textbox(name_ptr: I32.U8.UnsafePointer) do
        @form_element_list = cons(name_ptr, @form_element_list)
      end

      func rewind() do
        @body_chunk_index = 0
      end

      func next_body_chunk(), I32 do
        I32.match @body_chunk_index do
          0 ->
            reverse_in_place!(mut!(@form_element_list))
            @body_chunk_index = I32.when?(@form_element_list === 0, do: 6, else: 1)

            ~S[<form>\n]
            return()

          1 ->
            ~S[<label for="]

          2 ->
            # TODO: escape HTML
            hd!(@form_element_list)

          3 ->
            ~S[">\n  <input type="text" name="]

          4 ->
            hd!(@form_element_list)

          5 ->
            @form_element_list = tl!(@form_element_list)
            @body_chunk_index = I32.when?(@form_element_list === 0, do: 6, else: 1)

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

        @body_chunk_index = @body_chunk_index + 1
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

      Instance.run(__MODULE__, imports)
    end
  end
end
