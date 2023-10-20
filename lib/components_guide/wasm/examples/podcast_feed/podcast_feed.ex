defmodule ComponentsGuide.Wasm.PodcastFeed do
  use Orb
  use SilverOrb.BumpAllocator
  use ComponentsGuide.Wasm.Examples.StringBuilder
  use ComponentsGuide.Wasm.PodcastFeed.XMLFormatter

  SilverOrb.BumpAllocator.export_alloc()

  global :export_mutable do
    @title "hello"
    @description ""
    @author ""
    @link ""
    @language "en"
  end

  global do
    @episode_count 0

    @episode_pub_date_unix 0
    # @episode_duration "00:00:00"
    @episode_duration_hours 0
    @episode_duration_minutes 0
    @episode_duration_seconds 0
    @episode_mp3_byte_count 0
  end

  defmodule EpisodeID do
    def wasm_type(), do: :i32
  end

  # defwimport(populate_episode_at_index(episode_index: I32),
  #   to: :datasource,
  #   as: :datasource_populate_episode
  # )

  # defwimport :datasource do
  #   defwp(populate_episode_at_index(episode_index: I32), as: :datasource_populate_episode)
  # end

  # Import.func(:datasource, :populate_episode_at_index, as: :datasource_populate_episode, params: I32)
  # Func.import(:datasource, :populate_episode_at_index, as: :datasource_populate_episode, params: I32)
  # Global.import()
  # wasm_import(:datasource, populate_episode_at_index: Orb.DSL.funcp(name: :datasource_populate_episode, params: I32))

  wasm_import(:datasource,
    get_episodes_count: Orb.DSL.funcp(name: :get_episodes_count, result: I32),
    write_episode_id: Orb.DSL.funcp(name: :write_episode_id, params: {EpisodeID, I32}, result: I32),
    get_episode_pub_date_utc: Orb.DSL.funcp(name: :get_episode_pub_date_utc, params: EpisodeID, result: I32),
    get_episode_duration_seconds: Orb.DSL.funcp(name: :get_episode_duration_seconds, params: EpisodeID, result: I32),
    write_episode_title:
      Orb.DSL.funcp(name: :write_episode_title, params: {EpisodeID, I32}, result: I32),
    write_episode_author:
      Orb.DSL.funcp(name: :write_episode_author, params: {EpisodeID, I32}, result: I32),
    write_episode_description:
      Orb.DSL.funcp(name: :write_episode_description, params: {EpisodeID, I32}, result: I32),
    write_episode_link_url:
      Orb.DSL.funcp(name: :write_episode_link_url, params: {EpisodeID, I32}, result: I32),
    write_episode_mp3_url:
      Orb.DSL.funcp(name: :write_episode_mp3_url, params: {EpisodeID, I32}, result: I32),
    get_episode_mp3_byte_count:
      Orb.DSL.funcp(name: :get_episode_mp3_byte_count, params: EpisodeID, result: I32),
    write_episode_content_html:
      Orb.DSL.funcp(name: :write_episode_content_html, params: {EpisodeID, I32}, result: I32)
  )

  # 64KiB
  # Memory.add_named_pages(:episode_description_html, 1)

  # There are a few ways to implement this:
  # 1. Pass every episode in as some sort of data structure. e.g.
  # - JSON
  # - CSV
  # - URL encoded
  # 2. Call out to an imported callback function which populates
  # globals with each episode info.
  #
  # 1 uses more memory upfront, and requires a decoder in WebAssembly to
  # be implemented and included in the wasm module.
  # 2 is like the delegate pattern in Cocoa, but means there’s back-and-forth
  # between the wasm instance and the host.

  def guard(do: condition, else: result) do
    require Orb.DSL

    Orb.DSL.wasm do
      if not condition do
        result
      end
    end
  end

  def guard(condition, else: result) do
    require Orb.DSL

    Orb.DSL.wasm do
      if not condition do
        result
      end
    end
  end

  defw write_episodes_xml(), episode_count: I32, episode_index: I32 do
    episode_count = typed_call(I32, :get_episodes_count, [])
    # return do
    #   episode_count === 0
    # end
    # return() when episode_count === 0

    guard do
      episode_count > 0
    else
      return()
    end

    guard(episode_count > 0, else: return())

    if episode_count === 0, do: return()

    # loop Episodes when episode_index <= episode_count do
    loop Episodes do
      # _ = XML.build! :item do
      #   element :guid, isPermaLink: "false" do
      #     @bump_offset =
      #       @bump_offset + typed_call(I32, :write_episode_id, [episode_index, @bump_offset])
      #   end
      # end

      # XML.build! item: [
      #   guid: {[isPermaLink: "false"], [
      #     write_episode_data(:id, episode_index)
      #   ]},
      #   title: write_episode_data(:title, episode_index),
      #   "itunes:title": write_episode_data(:title, episode_index)
      # ]

      _ =
        build! do
          xml_open(:item)

          ~S[<guid isPermaLink="false">]
          ~S"<![CDATA["

          @bump_offset =
            @bump_offset + typed_call(I32, :write_episode_id, [episode_index, @bump_offset])

          ~S"]]>"
          ~S[</guid>\n]

          xml_open(:title)

          @bump_offset =
            @bump_offset + typed_call(I32, :write_episode_title, [episode_index, @bump_offset])

          xml_close_newline(:title)

          xml_open(:"itunes:title")

          @bump_offset =
            @bump_offset + typed_call(I32, :write_episode_title, [episode_index, @bump_offset])

          xml_close_newline(:"itunes:title")

          xml_open(:description)

          @bump_offset =
            @bump_offset +
              typed_call(I32, :write_episode_description, [episode_index, @bump_offset])

          xml_close_newline(:description)
          xml_open(:"itunes:subtitle")

          @bump_offset =
            @bump_offset +
              typed_call(I32, :write_episode_description, [episode_index, @bump_offset])

          xml_close_newline(:"itunes:subtitle")

          xml_close_newline(:item)
        end

      episode_index = episode_index + 1
      # assert!(episode_count === 1)
      # assert!(episode_count === 0)
      Episodes.continue(if: episode_index < episode_count)
    end
  end

  defw text_xml(), I32.String do
    build! do
      ~S[<?xml version="1.0" encoding="UTF-8"?>\n]
      ~S[<rss version="2.0"]
      ~S[ xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"]
      ~S[ xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0"]
      ~S[ xmlns:dc="http://purl.org/dc/elements/1.1/"]
      ~S[ xmlns:content="http://purl.org/rss/1.0/modules/content/">\n]

      # flush!() # Tell an imported callback to read the current data from memory.
      # This then causes the module to clear its local memory, resetting the bump
      # offset to the very beginning again.

      xml_open(:channel)
      xml_element(:title, @title)

      xml_element(:description, @description)
      xml_element(:"itunes:subtitle", @description)
      xml_element(:"itunes:author", @author)
      xml_element(:link, @link)
      xml_element(:language, @language)

      write_episodes_xml()

      # Spawns a WebAssembly instance to read the CSV line-by-line.
      # The instance has its own memory, which avoids tricky memory
      # allocation problems in this module while we are streaming out.
      # CSVReader.each :episodes do
      #   xml_element(:guid, [isPermaLink: "false"], CSVReader.read(:id))
      #   xml_element(:pubDate, CSVReader.read(:pub_date_unix))
      #   xml_element(:title, CSVReader.read(:title))
      # end

      # csv_read! [:id, :pub_date_unix, :title] do
      #   # The only problem is the output XML order is determined by the
      #   # input CSV, not us. Not a big deal for this use case.
      #   :id ->
      #     xml_element(:guid, [isPermaLink: "false"], csv_value_each_char)

      #   :pub_data_unix ->
      #     xml_element(:pubDate, csv_value_each_char)

      #   :title ->
      #     xml_element(:title, csv_value_each_char)
      # end

      # loop ReadCSV do
      #   I32.match  do

      #   end
      # end

      xml_close_newline(:channel)
      "</rss>\n"
    end
  end
end
