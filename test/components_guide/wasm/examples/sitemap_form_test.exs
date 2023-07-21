defmodule ComponentsGuide.Wasm.Examples.SitemapForm.Test do
  # FIXME
  use ExUnit.Case, async: true, register: false

  alias OrbWasmtime.{Instance, Wasm}
  alias ComponentsGuide.Wasm.Examples.SitemapForm

  test "index.html" do
    inst = Instance.run(SitemapForm)
    set_www_form_data = Instance.capture(inst, :set_www_form_data, 1)
    to_html = Instance.capture(inst, String, :html_index, 0)

    [
      {"urls[]", "https://example.org/a=1&b=2&c=3"},
      {"urls[]", "caf+@!<.org"}
    ]
    |> URI.encode_query()
    |> set_www_form_data.()

    html = to_html.()

    assert html =~ ~S{<!doctype html>}
    assert html =~ ~S{value="https://example.org/a=1&amp;b=2&amp;c=3"}
    assert html =~ ~S{value="caf+@!&lt;.org"}
  end

  test "bugs" do
    inst = Instance.run(SitemapForm)
    set_www_form_data = Instance.capture(inst, :set_www_form_data, 1)
    to_sitemap_xml = Instance.capture(inst, String, :xml_sitemap, 0)
    to_html = Instance.capture(inst, String, :html_index, 0)

    [
      {"urls[]", "https:"}
    ]
    |> URI.encode_query()
    |> set_www_form_data.()

    html = to_html.()

    assert html =~ ~S{<!doctype html>}
    assert html =~ ~S{value="https:"}

    assert to_sitemap_xml.() == ~S"""
           <?xml version="1.0" encoding="UTF-8"?>
           <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
           <url>
           <loc>https:</loc>
           </url>
           </urlset>
           """
  end

  test "sitemap.xml" do
    inst = Instance.run(SitemapForm)
    set_www_form_data = Instance.capture(inst, :set_www_form_data, 1)
    to_sitemap_xml = Instance.capture(inst, String, :xml_sitemap, 0)

    [
      {"urls[]", "https://example.org/a=1&b=2&c=3"},
      {"urls[]", "https://example.com/"}
      # {"urls[]", ""}
    ]
    |> URI.encode_query()
    |> set_www_form_data.()

    assert to_sitemap_xml.() == ~S"""
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
