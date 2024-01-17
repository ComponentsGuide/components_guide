defmodule ComponentsGuide.Wasm.PodcastFeed.Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.{Instance, Wasm}
  alias ComponentsGuide.Wasm.PodcastFeed

  defp wasm_imports(opts) do
    [
      {:datasource, :get_episodes_count, fn -> Keyword.get(opts, :episodes_count, 2) end},
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
       end}
    ]
  end

  test "podcast xml feed rendering" do
    # IO.puts(PodcastFeed.to_wat())

    inst = Instance.run(PodcastFeed, wasm_imports([]))

    # {title_offset, title_max_bytes} = Instance.call(inst, :get_title_memory_range)
    # title = "SOME TITLE" |> &[&1, ?\0] |> List.to_string()
    # assert byte_size(title) <= title_max_bytes
    # Instance.write_memory(inst, title_offset, title)

    title = Instance.alloc_string(inst, "SOME TITLE")
    Instance.set_global(inst, :title, title)

    description = Instance.alloc_string(inst, "SOME DESCRIPTION")
    Instance.set_global(inst, :description, description)

    author = Instance.alloc_string(inst, "Hall & Oates")
    Instance.set_global(inst, :author, author)

    text_xml_func = Instance.capture(inst, String, :text_xml, 0)
    text_xml = text_xml_func.()

    # IO.puts(PodcastFeed.to_wat())
    IO.puts(text_xml)

    assert text_xml =~ ~S"""
           <?xml version="1.0" encoding="UTF-8"?>
           """

    root = xml_parse(text_xml)

    assert "SOME DESCRIPTION" = xml_text_content(root, "/rss/channel/description[1]")
    # assert "SOME DESCRIPTION" = root["/rss/channel/description[1]"][:text]

    # assert {} = xml_xpath(root, "/rss/channel/itunes:author[1]") |> hd()
    assert "Hall & Oates" = xml_text_content(root, "/rss/channel/itunes:author[1]")

    [item1, item2] = xml_xpath(root, "//item")
    assert "1" = xml_text_content(item1, "//guid[@isPermaLink='false'][1]")
    assert "2" = xml_text_content(item2, "//guid[@isPermaLink='false'][1]")
    assert "Episode 1" = xml_text_content(item1, "//title[1]")
    assert "Episode 2" = xml_text_content(item2, "//title[1]")
    assert "Episode 1" = xml_text_content(item1, "//itunes:title[1]")
    assert "Episode 2" = xml_text_content(item2, "//itunes:title[1]")
    assert "Description for 1" = xml_text_content(item1, "//description[1]")
    assert "Description for 2" = xml_text_content(item2, "//description[1]")

    # <enclosure url="${bunnyEpisodeURL(episodeID)}" length="${feedItem.mp3ByteCount}" type="audio/mpeg"/>
    # assert "Description for 2" = xml_xpath(item1, "//enclosure[1]")
  end

  test "12,000 episodes" do
    inst = Instance.run(PodcastFeed, wasm_imports(episodes_count: 12_000))
    text_xml_func = Instance.capture(inst, String, :text_xml, 0)
    text_xml = text_xml_func.()

    assert text_xml =~ ~S"""
           <?xml version="1.0" encoding="UTF-8"?>
           """

    root = xml_parse(text_xml)
    items = xml_xpath(root, "//item")
    assert 12_000 = length(items)
  end

  defp xml_parse(xml) do
    {root, []} = xml |> String.to_charlist() |> :xmerl_scan.string()
    root
  end

  defp xml_xpath(el, xpath) when is_binary(xpath) do
    :xmerl_xs.select(String.to_charlist(xpath), el)
  end

  defp xml_text_content(el, xpath) when is_binary(xpath) do
    xml_xpath(el, xpath) |> hd() |> xml_text_content()
  end

  defp xml_text_content(el) do
    :xmerl_lib.foldxml(&do_xml_text_content/2, [], el)
    |> :lists.reverse()
    |> List.to_string()
  end

  require Record
  Record.defrecord(:xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl"))

  defp do_xml_text_content(node, acc) when Record.is_record(node, :xmlText) do
    [:xmerl_lib.flatten_text(xmlText(node, :value)) | acc]
  end

  defp do_xml_text_content(_, acc), do: acc

  # @tag :skip
  test "output optimized wasm" do
    path_wasm = Path.join(__DIR__, "podcast_feed_xml.wasm")
    path_wat = Path.join(__DIR__, "podcast_feed_xml.wat")
    path_opt_wasm = Path.join(__DIR__, "podcast_feed_xml_OPT.wasm")
    path_opt_wat = Path.join(__DIR__, "podcast_feed_xml_OPT.wat")
    wasm = Wasm.to_wasm(PodcastFeed)
    File.write!(path_wasm, wasm)
    System.cmd("wasm-opt", [path_wasm, "-o", path_opt_wasm, "-O"])

    %{size: size} = File.stat!(path_wasm)
    assert size == 2418

    %{size: size} = File.stat!(path_opt_wasm)
    assert size == 1909

    {wat, 0} = System.cmd("wasm2wat", [path_wasm])
    File.write!(path_wat, wat)
    {opt_wat, 0} = System.cmd("wasm2wat", [path_opt_wasm])
    File.write!(path_opt_wat, opt_wat)
  end
end
