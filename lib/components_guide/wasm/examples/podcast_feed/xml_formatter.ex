defmodule ComponentsGuide.Wasm.PodcastFeed.XMLFormatter do
  use Orb
  use SilverOrb.BumpAllocator
  use ComponentsGuide.Wasm.Examples.StringBuilder
  # use URLEncoded

  defwi xml_escape(str: I32.String), I32.String do
    build! do
      ~S"<![CDATA["
      # ~S"<![CDATA["
      # ~S"<!["
      # ~S"CDATA["
      append!(string: str)
      ~S"]]>"
    end
  end

  def open(tag) when is_atom(tag) do
    xml_open(Orb.DSL.const(Atom.to_string(tag)))
  end

  defwi xml_open(tag: I32.String), I32.String do
    build! do
      # "<" <> tag <> ">"
      "<"
      append!(string: tag)
      ">"
    end
  end

  def close_newline(tag) when is_atom(tag) do
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

  def element(tag, child) when is_atom(tag) do
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

  defmacro build(tag, do: block) do
    quote do
      [
        Orb.DSL.drop(unquote(__MODULE__).open(unquote(tag))),
        # Orb.DSL.drop(build! do: unquote(block))
        unquote(Orb.__get_block_items(block)),
        # unquote(block),
        Orb.DSL.drop(unquote(__MODULE__).close_newline(unquote(tag)))
      ]
    end
  end

  defmacro __using__(as: some_alias) do
    quote do
      require unquote(__MODULE__), as: unquote(some_alias)
      Orb.include(unquote(__MODULE__))
    end
  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Orb.include(unquote(__MODULE__))
    end
  end
end
