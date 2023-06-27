defmodule ComponentsGuide.Wasm.Examples.SitemapForm do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.LinkedLists
  alias ComponentsGuide.Wasm.Examples.HTML.EscapeHTML

  # defmodule CounterHTMLFuture do
  #   defcomponent Counter state: [
  #     count: 0
  #   ] do
  #     body do
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

  defmodule SitemapBuilder do
    use Wasm
    use BumpAllocator, export: true
    use LinkedLists

    wasm_memory(pages: 3)

    @page_size 64 * 1024
    @bump_start 1 * @page_size
    @output_offset 2 * @page_size

    I32.export_global(:readonly,
      input_offset: @bump_start
    )

    I32.export_enum([:editing, :rendering_html_form, :rendering_xml_sitemap])

    I32.global(
      mode: 0,
      body_chunk_index: 0,
      output_offset: @output_offset,
      url_list: 0x0
    )

    #     wasm U32 do
    #       EscapeHTML.funcp(:escape)
    # 
    #       func rewind() do
    #         @body_chunk_index = 0
    #       end
    # 
    #       func add_url(str_ptr: I32.U8.Pointer) do
    #         # @url_list = cons(str_ptr, @url_list)
    #         append_url_query(~S"url[]", str_ptr)
    #       end
    # 
    #       func set_form_data(form_data_ptr: I32.U8.Pointer) do
    #         # TODO: replace @url_list with data deserialized from form.
    #       end
    # 
    #       func next_body_chunk(), I32 do
    #         I32.match @body_chunk_index do
    #           0 ->
    #             reverse_in_place!(mut!(@url_list))
    #             @body_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
    # 
    #             ~S[<form>\n]
    # 
    #             return()
    # 
    #           1 ->
    #             ~S"""
    #             <label for="input-n">URL n</label>
    #             """
    # 
    #           2 ->
    #             ~S[<input id="input-n" value="]
    # 
    #           3 ->
    #             # {start, len} = next_url_query_item(@form_data)
    #             str = FormData.clone_first_value(@form_data, key: ~S"url[]")
    # 
    #             build! do
    #               # append_escaped_html!(start, len)
    #               append_escaped_html!(str)
    #             end
    # 
    #           # TODO: undo allocations next chunk around.
    # 
    #           # call(:escape, hd!(@url_list), @output_offset)
    #           # push(@output_offset)
    # 
    #           4 ->
    #             # @url_list = tl!(@url_list)
    #             @form_data = FormData.next_pair(@form_data)
    # 
    #             @body_chunk_index = @form_data |> I32.eqz?(do: 4, else: 1)
    # 
    #             ~S"""
    #             </loc>
    #             </url>
    #             """
    # 
    #             return()
    # 
    #           _ ->
    #             0x0
    #             return()
    #         end
    # 
    #         @body_chunk_index = @body_chunk_index + 1
    #       end
    # 
    #       func sitemap_xml_next_chunk(), I32 do
    #         I32.match @body_chunk_index do
    #           0 ->
    #             reverse_in_place!(mut!(@url_list))
    #             @body_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
    # 
    #             ~S"""
    #             <?xml version="1.0" encoding="UTF-8"?>
    #             <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #             """
    # 
    #             return()
    # 
    #           1 ->
    #             ~S"<url>\n<loc>"
    # 
    #           2 ->
    #             call(:escape, hd!(@url_list), @output_offset)
    #             push(@output_offset)
    # 
    #           3 ->
    #             @url_list = tl!(@url_list)
    #             @body_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
    # 
    #             ~S"""
    #             </loc>
    #             </url>
    #             """
    # 
    #             # if @url_list do
    #             #   @body_chunk_index = 1
    #             #   return()
    #             # end
    # 
    #             return()
    # 
    #           4 ->
    #             reverse_in_place!(mut!(@url_list))
    # 
    #             ~S"""
    #             </urlset>
    #             """
    # 
    #           _ ->
    #             0x0
    #             return()
    #         end
    # 
    #         @body_chunk_index = @body_chunk_index + 1
    #       end
    # 
    #       func sitemap_xml_next_chunk(), I32 do
    #         I32.match @body_chunk_index do
    #           0 ->
    #             reverse_in_place!(mut!(@url_list))
    #             @body_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
    # 
    #             ~S"""
    #             <?xml version="1.0" encoding="UTF-8"?>
    #             <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #             """
    # 
    #             return()
    # 
    #           1 ->
    #             ~S"<url>\n<loc>"
    # 
    #           2 ->
    #             call(:escape, hd!(@url_list), @output_offset)
    #             push(@output_offset)
    # 
    #           3 ->
    #             @url_list = tl!(@url_list)
    #             @body_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
    # 
    #             ~S"""
    #             </loc>
    #             </url>
    #             """
    # 
    #             # if @url_list do
    #             #   @body_chunk_index = 1
    #             #   return()
    #             # end
    # 
    #             return()
    # 
    #           4 ->
    #             reverse_in_place!(mut!(@url_list))
    # 
    #             ~S"""
    #             </urlset>
    #             """
    # 
    #           _ ->
    #             0x0
    #         end
    # 
    #         @body_chunk_index = @body_chunk_index + 1
    #       end
    # end

    def read_body(instance) do
      Instance.call(instance, "rewind")
      Instance.call_stream_string_chunks(instance, "next_body_chunk") |> Enum.join()
    end
  end

  defmodule HTMLFormBuilder do
    use Wasm
    use BumpAllocator, export: true
    use LinkedLists

    wasm_memory(pages: 3)

    # @textbox_tuple Tuple.define(name: I32, label: I32)

    I32.global(
      body_chunk_index: 0,
      form_element_list: 0x0
    )

    # wasm_import(
    #   log: [
    #     int32: func(name: :log32, params: I32, result: I32)
    #   ]
    # )

    wasm_import(:log, :int32, func(name: :log32, params: I32, result: I32))

    wasm U32 do
      EscapeHTML.funcp(:escape)

      func add_textbox(name_ptr: I32.U8.Pointer) do
        @form_element_list = cons(name_ptr, @form_element_list)
      end

      func rewind() do
        @body_chunk_index = 0
      end

      func next_body_chunk(), I32 do
        I32.match @body_chunk_index do
          0 ->
            reverse_in_place!(mut!(@form_element_list))
            @body_chunk_index = @form_element_list |> I32.eqz?(do: 6, else: 1)

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

      ComponentsGuide.Wasm.run_instance(__MODULE__, imports)
    end
  end
end
