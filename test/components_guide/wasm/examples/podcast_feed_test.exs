defmodule ComponentsGuide.Wasm.PodcastFeed.Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.{Instance, Wasm}
  alias ComponentsGuide.Wasm.PodcastFeed

  test "url_encoded_count" do
    # IO.puts(PodcastFeed.to_wat())

    inst = Instance.run(PodcastFeed)

    title = Instance.alloc_string(inst, "SOME TITLE")
    Instance.set_global(inst, :title, title)

    description = Instance.alloc_string(inst, "SOME DESCRIPTION")
    Instance.set_global(inst, :description, description)

    text_xml_func = Instance.capture(inst, String, :text_xml, 0)
    text_xml = text_xml_func.()

    assert text_xml =~ ~S"""
    <?xml version="1.0" encoding="UTF-8"?>
    """
    assert text_xml =~ ~S|<title><![CDATA[SOME TITLE]]></title>|
    assert text_xml =~ ~S|<description><![CDATA[SOME DESCRIPTION]]></description>|
    assert text_xml =~ ~S|<itunes:subtitle><![CDATA[SOME DESCRIPTION]]></itunes:subtitle>|
  end
end
