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
    func set_www_form_data(data_ptr: URLEncoded) do
      # TODO: validate
      @data_url_encoded = data_ptr
    end

    func html_index(), I32.String,
      count: I32,
      query_iterator: URLEncoded,
      i: I32,
      value_char_iterator: URLEncoded.Value.CharIterator,
      value_char: I32.U8 do
      count = URLEncoded.count(@data_url_encoded)

      build! do
        ~S"""
        <!doctype html><html lang=en><meta charset=utf-8>
        <meta name=viewport content="width=device-width, initial-scale=1.0">
        <title>Sitemap form using WebAssembly</title>
        """

        # ~S[<script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio,line-clamp"></script>]
        ~S"""
        <style>
        :root { font-size: 150%; font-family: system-ui, sans-serif; }
        :root { --size-factor: 1; --margin-y: 0; --margin-x: 0 }
        * { margin: var(--margin-y) var(--margin-x); }

        h1, h2, h3, h4, h5, h6, input, button {
          font-size: calc(1rem * var(--size-factor));
          line-height: calc(var(--size-factor) * 1rlh)
        }

        h1 { --size-factor: 2; --margin-y: 1rlh }

        form { display: flex; flex-direction: column; align-items: center; gap: 1rem; }
        label { font-weight: bold }
        input { padding: 0.5rem; border: 1px solid currentColor }
        button { padding: 0.5rem 1rem; background: #ddd; border: 1px solid #ccc }
        button[data-strong] { color: white; background: #222; border-color: #222 }
        fieldset { display: flex; flex-wrap: wrap; gap: 1rem; align-items: center; justify-content: center; border: none; padding: 0 }
        </style>
        """

        ~S[<form>\n]
        ~S[<h1>Edit URLs</h1>\n]

        query_iterator = @data_url_encoded
        # query_iterator = URLEncoded.each_pair(@data_url_encoded)

        loop EachItem, while: I32.eqz(URLEncoded.empty?(query_iterator)) do
          value_char_iterator = URLEncoded.Value.each_char(query_iterator)

          if value_char_iterator do
            append!(
              string: ~S[<fieldset>],
              string: ~S[<label for="url-],
              decimal_u32: i + 1,
              string: ~S[">],
              decimal_u32: i + 1,
              string: ~S[</label>],
              string: ~S{<input type=url name=urls[] id="url-},
              decimal_u32: i + 1,
              string: ~S{" value="}
            )

            loop value_char <- value_char_iterator do
              # assert!(I32.eqz(I32.eq(value_char, 0)))
              append_html_escaped!(char: value_char)
            end

            append!(~S[">])
            append!(~S[</fieldset>\n])
          end

          query_iterator = URLEncoded.rest(query_iterator)
          i = i + 1

          # EachItem.continue(if: URLEncoded.count(query_iterator))
        end

        ~S[<label for=add-url>Add URL</label>\n]
        ~S{<input id=add-url type=url name=urls[] value="">\n}

        ~S[<button data-strong>Update</button>\n]
        ~S[<button formaction="sitemap.xml" formtarget="_blank">View XML Sitemap</button>\n]

        ~S[</form>\n]
      end
    end

    func xml_sitemap(), I32.String,
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

        loop EachItem, while: I32.eqz(URLEncoded.empty?(query_iterator)) do
          value_char_iterator = URLEncoded.Value.each_char(query_iterator)

          if value_char_iterator do
            ~S"<url>\n<loc>" |> append!()

            loop value_char <- value_char_iterator do
              # assert!(I32.eqz(I32.eq(value_char, 0)))

              append_html_escaped!(char: value_char)
            end

            ~S"""
            </loc>
            </url>
            """
            |> append!()
          end

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
  end

  def read_body(instance) do
    Instance.call(instance, "rewind")
    Instance.call_stream_string_chunks(instance, "next_body_chunk") |> Enum.join()
  end
end
