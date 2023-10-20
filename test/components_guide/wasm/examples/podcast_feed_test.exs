defmodule ComponentsGuide.Wasm.PodcastFeed.Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.{Instance, Wasm}
  alias ComponentsGuide.Wasm.PodcastFeed

  test "podcast xml feed rendering" do
    # IO.puts(PodcastFeed.to_wat())

    inst =
      Instance.run(
        PodcastFeed,
        [
          {:datasource, :get_episodes_count, fn -> 2 end},
          {:datasource, :write_episode_id,
           fn caller, id, write_at ->
             s = "#{id + 1}"

             Instance.Caller.write_string_nul_terminated(caller, write_at, s) -
               1
           end},
          {:datasource, :get_episode_pub_date_utc, fn id -> 0 end},
          {:datasource, :get_episode_duration_seconds, fn id -> 0 end},
          {:datasource, :write_episode_title,
           fn caller, id, write_at ->
             s = "Episode #{id + 1}"

             Instance.Caller.write_string_nul_terminated(caller, write_at, s) -
               1
           end},
          {:datasource, :write_episode_author,
           fn caller, id, write_at ->
             s = "Some author"

             Instance.Caller.write_string_nul_terminated(caller, write_at, s) -
               1
           end},
          {:datasource, :write_episode_description,
           fn caller, id, write_at ->
             s = "Description for #{id + 1}"

             Instance.Caller.write_string_nul_terminated(caller, write_at, s) -
               1
           end},
           {:datasource, :write_episode_link_url,
           fn caller, id, write_at ->
             s = ""

             Instance.Caller.write_string_nul_terminated(caller, write_at, s) -
               1
           end},
           {:datasource, :write_episode_mp3_url,
           fn caller, id, write_at ->
             s = ""

             Instance.Caller.write_string_nul_terminated(caller, write_at, s) -
               1
           end},
           {:datasource, :get_episode_mp3_byte_count, fn id -> 0 end},
           {:datasource, :write_episode_content_html,
           fn caller, id, write_at ->
             s = ""

             Instance.Caller.write_string_nul_terminated(caller, write_at, s) -
               1
           end},
        ]
      )

    title = Instance.alloc_string(inst, "SOME TITLE")
    Instance.set_global(inst, :title, title)

    description = Instance.alloc_string(inst, "SOME DESCRIPTION")
    Instance.set_global(inst, :description, description)

    text_xml_func = Instance.capture(inst, String, :text_xml, 0)
    text_xml = text_xml_func.()

    # assert text_xml === ""

    assert text_xml =~ ~S"""
           <?xml version="1.0" encoding="UTF-8"?>
           """

    root = xml_parse(text_xml)

    assert xml_select(root, "/rss/channel/description[1]", :text) == "SOME DESCRIPTION"
    # assert root["/rss/channel/description[1]"][:text] == "SOME DESCRIPTION"

    found_items = xml_xpath(root, "//item")
    assert length(found_items) == 2

    [item1, item2] = found_items
    assert xml_select(item1, "//guid[1]", :text) == "1"
    assert xml_select(item2, "//guid[1]", :text) == "2"
    assert xml_select(item1, "//title[1]", :text) == "Episode 1"
    assert xml_select(item2, "//title[1]", :text) == "Episode 2"
    assert xml_select(item1, "//itunes:title[1]", :text) == "Episode 1"
    assert xml_select(item2, "//itunes:title[1]", :text) == "Episode 2"
    assert xml_select(item1, "//description[1]", :text) == "Description for 1"
    assert xml_select(item2, "//description[1]", :text) == "Description for 2"
  end

  defp xml_parse(xml) do
    {root, []} = xml |> String.to_charlist() |> :xmerl_scan.string()
    root
  end

  defp xml_xpath(el, xpath) when is_binary(xpath) do
    :xmerl_xs.select(String.to_charlist(xpath), el)
  end

  defp xml_select(el, xpath, :text) when is_binary(xpath) do
    xml_xpath(el, xpath) |> hd() |> xml_text_content()
  end

  defp xml_text_content(el) do
    el |> :xmerl_xs.value_of() |> List.to_string()
  end
end
