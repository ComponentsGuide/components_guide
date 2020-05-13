# Paredown: simplified Markdown subset
defmodule ComponentsGuideWeb.DownView do
  defmodule ParserState do
    defstruct html: [], italics: nil, bold: nil, link: nil, link_references: %{}

    def parse(input, options) when is_binary(input) do
      %__MODULE__{
        link_references: Access.get(options, :links, %{})
      }
      |> next(input)
    end

    # Links

    defp next(state = %__MODULE__{link: nil}, <<"["::utf8>> <> rest) do
      %__MODULE__{state | link: {:capturing_text, []}}
      |> next(rest)
    end

    defp next(state = %__MODULE__{link: {:capturing_text, text_chars}}, <<"]"::utf8>> <> rest) do
      %__MODULE__{state | link: {:ready_for_url, text_chars}}
      |> next(rest)
    end

    defp next(
           state = %__MODULE__{link: {:capturing_text, text_chars}},
           <<char::utf8>> <> rest
         ) do
      %__MODULE__{state | link: {:capturing_text, [char | text_chars]}}
      |> next(rest)
    end

    defp next(state = %__MODULE__{link: {:ready_for_url, text_chars}}, <<"("::utf8>> <> rest) do
      %__MODULE__{state | link: {:capturing_url, text_chars, []}}
      |> next(rest)
    end

    defp next(state = %__MODULE__{link: {:ready_for_url, text_chars}}, <<"["::utf8>> <> rest) do
      %__MODULE__{state | link: {:capturing_url_reference, text_chars, []}}
      |> next(rest)
    end

    defp next(state = %__MODULE__{link: {:ready_for_url, text_chars}}, rest) do
      text = text_chars |> Enum.reverse() |> List.to_string()
      url = Map.get(state.link_references, text, "")
      anchor_html = Phoenix.HTML.Link.link(text, to: url) |> Phoenix.HTML.safe_to_string()

      %__MODULE__{state | html: [anchor_html | state.html], link: nil}
      |> next(rest)
    end

    defp next(
           state = %__MODULE__{link: {:capturing_url, text_chars, url_chars}},
           <<")"::utf8>> <> rest
         ) do
      text = text_chars |> Enum.reverse() |> List.to_string()
      url = url_chars |> Enum.reverse() |> List.to_string()
      anchor_html = Phoenix.HTML.Link.link(text, to: url) |> Phoenix.HTML.safe_to_string()

      %__MODULE__{state | html: [anchor_html | state.html], link: nil}
      |> next(rest)
    end

    defp next(
           state = %__MODULE__{link: {:capturing_url, text_chars, url_chars}},
           <<char::utf8>> <> rest
         ) do
      %__MODULE__{state | link: {:capturing_url, text_chars, [char | url_chars]}}
      |> next(rest)
    end

    defp next(
           state = %__MODULE__{link: {:capturing_url_reference, text_chars, url_reference_chars}},
           <<"]"::utf8>> <> rest
         ) do
      text = text_chars |> Enum.reverse() |> List.to_string()
      url_reference = url_reference_chars |> Enum.reverse() |> List.to_string()
      url = Map.get(state.link_references, url_reference, "")
      anchor_html = Phoenix.HTML.Link.link(text, to: url) |> Phoenix.HTML.safe_to_string()

      %__MODULE__{state | html: [anchor_html | state.html], link: nil}
      |> next(rest)
    end

    defp next(
           state = %__MODULE__{link: {:capturing_url_reference, text_chars, url_reference_chars}},
           <<char::utf8>> <> rest
         ) do
      %__MODULE__{
        state
        | link: {:capturing_url_reference, text_chars, [char | url_reference_chars]}
      }
      |> next(rest)
    end

    # Bold

    defp next(state = %__MODULE__{bold: nil}, <<"**"::utf8>> <> rest) do
      %__MODULE__{state | html: ["<strong>" | state.html], bold: "**"}
      |> next(rest)
    end

    defp next(state = %__MODULE__{bold: "**"}, <<"**"::utf8>> <> rest) do
      %__MODULE__{state | html: ["</strong>" | state.html], bold: nil}
      |> next(rest)
    end

    # Italics

    defp next(state = %__MODULE__{italics: nil}, <<"_"::utf8>> <> rest) do
      %__MODULE__{state | html: ["<em>" | state.html], italics: "_"}
      |> next(rest)
    end

    defp next(state = %__MODULE__{italics: "_"}, <<"_"::utf8>> <> rest) do
      %__MODULE__{state | html: ["</em>" | state.html], italics: nil}
      |> next(rest)
    end

    defp next(state = %__MODULE__{italics: nil}, <<"*"::utf8>> <> rest) do
      %__MODULE__{state | html: ["<em>" | state.html], italics: "*"}
      |> next(rest)
    end

    defp next(state = %__MODULE__{italics: "*"}, <<"*"::utf8>> <> rest) do
      %__MODULE__{state | html: ["</em>" | state.html], italics: nil}
      |> next(rest)
    end

    defp next(state = %__MODULE__{}, <<char::utf8>> <> rest) do
      %__MODULE__{state | html: [<<char::utf8>> | state.html]}
      |> next(rest)
    end

    defp next(state = %__MODULE__{}, "") do
      html = state.html |> Enum.reverse() |> Enum.join()
      Phoenix.HTML.raw(html)
    end
  end

  def down(input, options \\ %{}) when is_binary(input) do
    ParserState.parse(input, options)
  end
end
