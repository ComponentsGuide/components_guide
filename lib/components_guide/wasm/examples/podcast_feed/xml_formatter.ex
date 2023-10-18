defmodule ComponentsGuide.Wasm.PodcastFeed.XMLFormatter do
  use Orb
  use SilverOrb.BumpAllocator
  use ComponentsGuide.Wasm.Examples.StringBuilder
  # use URLEncoded

  defwi xml_escape(str: I32.String), I32.String do
    build! do
      # ~S"<![CDATA["
      # ~S"<![CDATA["
      ~S"<!["
      ~S"CDATA["
      append!(string: str)
      ~S"]]>"
    end
  end

  def xml_open_newline(tag) when is_atom(tag) do
    xml_open_newline(Orb.DSL.const(Atom.to_string(tag)))
  end

  defwi xml_open_newline(tag: I32.String), I32.String do
    build! do
      # "<" <> tag <> ">"
      "<"
      append!(string: tag)
      ">\n"
    end
  end

  def xml_close_newline(tag) when is_atom(tag) do
    xml_close_newline(Orb.DSL.const(Atom.to_string(tag)))
  end

  defwi xml_close_newline(tag: I32.String), I32.String do
    build! do
      # "</" <> tag <> ">"
      "</"
      append!(string: tag)
      ">\n"
    end
  end

  def xml_element(tag, child) when is_atom(tag) do
    tag = Orb.DSL.const(Atom.to_string(tag))
    xml_element(tag, child)
  end

  defwi xml_element(tag: I32.String, child: I32.String), I32.String do
    build! do
      # "<" <> tag <> ">"
      ~S"<"
      append!(string: tag)
      ~S">"
      xml_escape(child)
      ~S"</"
      append!(string: tag)
      ~S">\n"
    end
  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Orb.include(unquote(__MODULE__))
    end
  end
end
