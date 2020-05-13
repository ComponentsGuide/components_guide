defmodule ComponentsGuideWeb.DownView do
  use ComponentsGuideWeb, :view

  defmodule ParserState do
    defstruct bold: false, italics: false, html: []

    @spec parse(binary) ::
            {:safe,
             binary
             | maybe_improper_list(
                 binary | maybe_improper_list(any, binary | []) | byte,
                 binary | []
               )}
    def parse(input) when is_binary(input) do
      next(%__MODULE__{}, input)
    end

    defp next(state = %__MODULE__{italics: true}, <<"_"::utf8>> <> rest) do
      %__MODULE__{state | html: [state.html], italics: false}
      |> next(rest)
    end

    defp next(state = %__MODULE__{italics: false}, <<"_"::utf8>> <> rest) do
      %__MODULE__{state | html: ["<em1>" | state.html], italics: true}
      |> next(rest)
    end

    defp next(state = %__MODULE__{}, <<char::utf8>> <> rest) do
      %__MODULE__{state | html: [<<char::utf8>> | state.html]}
      |> next(rest)
    end

    defp next(state = %__MODULE__{italics: italics}, "") do
      html = Enum.reverse(state.html) |> Enum.join()

      html =
        case italics do
          true ->
            html <> "</em>"

          false ->
            html
        end

      Phoenix.HTML.raw(html)
    end
  end

  def down(input) when is_binary(input) do
    ParserState.parse(input)
  end
end
