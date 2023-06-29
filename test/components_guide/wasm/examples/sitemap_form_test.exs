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

    [
      {"urls[]", "example.org"},
      {"urls[]", "example.org"}
    ]
    |> URI.encode_query()
    |> set_www_form_data.()

    assert to_html.() == ~S"""
           <form>
           count: 2;
           1 example.org
           2 example.org
           </form>
           """
  end
end
