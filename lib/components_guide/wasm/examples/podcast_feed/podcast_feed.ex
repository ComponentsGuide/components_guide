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

  defw text_xml(), I32.String do
    build! do
      ~S[<?xml version="1.0" encoding="UTF-8"?>\n]
      ~S[<rss version="2.0"]
      ~S[xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"]
      ~S[xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0"]
      ~S[xmlns:dc="http://purl.org/dc/elements/1.1/"]
      ~S[xmlns:content="http://purl.org/rss/1.0/modules/content/">\n]

      xml_open_newline(:channel)
      xml_element(:title, @title)

      xml_element(:description, @description)
      xml_element(:"itunes:subtitle", @description)
      xml_element(:"itunes:author", @author)
      xml_element(:link, @link)
      xml_element(:language, @language)

      xml_close_newline(:channel)
      "</rss>\n"
    end
  end
end
