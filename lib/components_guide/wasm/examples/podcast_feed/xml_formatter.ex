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

  def open(tag, attributes \\ []) when is_atom(tag) do
    [
      append!(string: "<#{tag}"),
      for {attribute_name, value} <- attributes do
        [
          append!(string: " #{attribute_name}=\""),
          append!(string: value),
          append!(ascii: ?")
        ]
      end,
      append!(ascii: ?>)
    ]
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

  defmodule BuildToken do
    defstruct(position: :start, body: nil)

    def start() do
      %__MODULE__{position: :start}
    end

    def finish() do
      %__MODULE__{position: :finish}
    end

    def inner_start() do
      %__MODULE__{position: :inner_start, body: append!(string: "<![CDATA[")}
    end

    def inner_finish() do
      %__MODULE__{position: :inner_finish, body: append!(string: "]]>")}
    end

    defimpl Orb.ToWat do
      def to_wat(%BuildToken{body: nil}, _), do: []

      def to_wat(%BuildToken{body: body}, indent) do
        Orb.ToWat.to_wat(body, indent)
      end
    end
  end

  defmacro element(tag, attributes \\ [], content)

  defmacro element(tag, attributes, do: block) do
    quote do
      [
        BuildToken.start(),
        unquote(__MODULE__).open(unquote(tag), unquote(attributes)),
        BuildToken.inner_start(),
        unquote_splicing(Orb.__get_block_items(block)),
        BuildToken.inner_finish(),
        Orb.Stack.drop(unquote(__MODULE__).close_newline(unquote(tag))),
        BuildToken.finish()
      ]
      |> List.flatten()
      |> Enum.reduce([], fn x, acc ->
        case {x, acc} do
          {%BuildToken{position: :start}, [%BuildToken{position: :inner_start} | tail]} ->
            tail

          {%BuildToken{position: :inner_finish}, [%BuildToken{position: :finish} | tail]} ->
            tail

          _ ->
            [x | acc]
        end
      end)
      |> :lists.reverse()
    end
  end

  defmacro element(tag, _attributes, content) do
    quote do
      unquote(__MODULE__).xml_element(
        Orb.DSL.const(Atom.to_string(unquote(tag))),
        unquote(content)
      )
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
