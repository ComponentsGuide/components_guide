defmodule ComponentsGuide.Wasm.Examples.SitemapForm.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.SitemapForm

  # @tag :skip
  test "url_encoded_count" do
    inst = Instance.run(SitemapForm)
    set_www_form_data = Instance.capture(inst, :set_www_form_data, 1)
    to_html = Instance.capture(inst, String, :to_html, 0)

    set_www_form_data.(URI.encode_query(%{"urls[]" => "example.org"}))

    assert to_html.() == ~S"""
           <form>
           1
           </form>
           """
  end
end
