defmodule ComponentsGuide.Wasm.Examples.SitemapForm do
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.HTML.BuildHTML
  alias ComponentsGuide.Wasm.Examples.StringBuilder
  alias ComponentsGuide.Wasm.Examples.URLEncoded

  use Orb
  use BumpAllocator
  # use StringBuilder
  use URLEncoded
  use BuildHTML

  BumpAllocator.export_alloc()

  # wasm_memory(pages: 3)

  I32.export_enum([:editing, :rendering_html_form, :rendering_xml_sitemap])

  I32.global(
    mode: 0,
    output_chunk_index: 0,
    data_url_encoded: URLEncoded
  )

  wasm U32 do
    # 
    #       func rewind() do
    #         @output_chunk_index = 0
    #       end
    # 
    func set_www_form_data(data_ptr: URLEncoded) do
      # TODO: validate
      @data_url_encoded = data_ptr
    end

    func to_html(), I32.String,
      count: I32,
      query_iterator: URLEncoded,
      i: I32,
      value_char_iterator: URLEncoded.Value.CharIterator,
      value_char: I32.U8 do
      count = URLEncoded.count(@data_url_encoded)

      build! do
        ~S[<form>\n]
        ~S[count: ]

        append!(
          decimal_u32: count,
          ascii: ?;,
          ascii: ?\n
        )

        query_iterator = @data_url_encoded
        # query_iterator = URLEncoded.each_pair(@data_url_encoded)

        loop EachItem do
          append!(decimal_u32: i + 1, ascii: 0x20)

          value_char_iterator = URLEncoded.Value.each_char(query_iterator)

          loop value_char <- value_char_iterator do
            append_html_escaped!(char: value_char)
            # append!(u8: value_char)
          end

          append!(ascii: ?\n)

          query_iterator = URLEncoded.rest(query_iterator)
          i = i + 1

          EachItem.continue(if: URLEncoded.count(query_iterator))
        end

        ~S[</form>\n]
      end
    end

    func to_sitemap_xml(), I32.String,
      count: I32,
      query_iterator: URLEncoded,
      i: I32,
      value_char_iterator: URLEncoded.Value.CharIterator,
      value_char: I32.U8 do
      count = URLEncoded.count(@data_url_encoded)

      build! do
        ~S"""
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        """
        |> append!()

        query_iterator = @data_url_encoded
        # query_iterator = URLEncoded.each_pair(@data_url_encoded)

        loop EachItem do
          ~S"<url>\n<loc>" |> append!()

          value_char_iterator = URLEncoded.Value.each_char(query_iterator)

          loop value_char <- value_char_iterator do
            if value_char do
              append_html_escaped!(char: value_char)
            end
          end

          ~S"""
          </loc>
          </url>
          """
          |> append!()

          query_iterator = URLEncoded.rest(query_iterator)
          i = i + 1

          EachItem.continue(if: URLEncoded.count(query_iterator))
        end

        ~S"""
        </urlset>
        """
        |> append!()
      end
    end

    #       func sitemap_xml_next_chunk(), I32 do
    #         I32.match @output_chunk_index do
    #           0 ->
    #             reverse_in_place!(mut!(@url_list))
    #             @output_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
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
    #             @output_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
    # 
    #             ~S"""
    #             </loc>
    #             </url>
    #             """
    # 
    #             # if @url_list do
    #             #   @output_chunk_index = 1
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
    #         @output_chunk_index = @output_chunk_index + 1
    #       end
    # 
    #       func sitemap_xml_next_chunk(), I32 do
    #         I32.match @output_chunk_index do
    #           0 ->
    #             reverse_in_place!(mut!(@url_list))
    #             @output_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
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
    #             @output_chunk_index = @url_list |> I32.eqz?(do: 4, else: 1)
    # 
    #             ~S"""
    #             </loc>
    #             </url>
    #             """
    # 
    #             # if @url_list do
    #             #   @output_chunk_index = 1
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
    #         @output_chunk_index = @output_chunk_index + 1
    #       end
  end

  def read_body(instance) do
    Instance.call(instance, "rewind")
    Instance.call_stream_string_chunks(instance, "next_body_chunk") |> Enum.join()
  end
end
