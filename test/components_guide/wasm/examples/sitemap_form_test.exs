defmodule ComponentsGuide.Wasm.Examples.SitemapForm.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.SitemapForm

  # @tag :skip
  test "index.html" do
    inst = Instance.run(SitemapForm)
    set_www_form_data = Instance.capture(inst, :set_www_form_data, 1)
    to_html = Instance.capture(inst, String, :to_html, 0)

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

  test "sitemap.xml" do
    inst = Instance.run(SitemapForm)
    set_www_form_data = Instance.capture(inst, :set_www_form_data, 1)
    to_sitemap_xml = Instance.capture(inst, String, :to_sitemap_xml, 0)

    [
      {"urls[]", "https://example.org/a=1&b=2&c=3"},
      {"urls[]", "https://example.com/"}
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
