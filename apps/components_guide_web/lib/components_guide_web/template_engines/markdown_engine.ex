defmodule ComponentsGuideWeb.TemplateEngines.MarkdownEngine do
  @moduledoc false

  @behaviour Phoenix.Template.Engine

  require Earmark

  def compile(path, name) do
    IO.puts("compile #{path} #{name}")
    html = path
    |> File.read!()
    |> Earmark.as_html!(%Earmark.Options{code_class_prefix: "language-", smartypants: false})

    # regex = ~r{<live-([\w-]+)>(.+)</live-([\w-]+)>}
    regex = ~r{<live-([\w-]+)>([^<]+)</live-([^>]+)>}
    # regex = ~r{<live-([\w-]+)>}

    # live? = Regex.match(regex, html)

    html = Regex.replace(regex, html, fn whole, name, content ->
      case name do
        "render" ->
          module = content |> String.trim #|> String.to_existing_atom
          "<div><%= live_render(@conn, #{module}, session: %{}) %></div>"
        _ ->
          "!" <> name <> "!" <> content
      end
    end)

    # html = Regex.replace(regex, html, fn whole, name, content -> "!" <> name <> "!" <> content end)

    # html = Regex.replace(regex, html, fn whole, name, content -> "<div><%= live_render(@conn, ComponentsGuideWeb.FakeSearchLive, session: %{}) %></div>" end)

    html |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)

    # case live? do
    #   true ->
    #     html |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)

    #   false ->

    # end
    # html |> EEx.compile_string(engine: Phoenix.LiveView.Engine, file: path, line: 1)
  end
end
