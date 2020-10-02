defmodule ComponentsGuideWeb.TemplateEngines.MarkdownEngine do
  @moduledoc false

  @behaviour Phoenix.Template.Engine

  require Earmark

  def compile(path, _name) do
    IO.puts("compile #{path}")
    html = path
    |> File.read!()
    |> Earmark.as_html!(%Earmark.Options{code_class_prefix: "language-", smartypants: false})

    # regex = ~r{<live-([\w-]+)>(.+)</live-([\w-]+)>}
    regex = ~r{<live-([\w-]+)>([^<]+)</live-([^>]+)>}
    # regex = ~r{<live-([\w-]+)>}

    html = Regex.replace(regex, html, fn whole, name, content -> name end)
    # html = Regex.replace(regex, html, fn whole, name, content -> "<div><%= live_render(@conn, ComponentsGuideWeb.FakeSearchLive, session: %{}) %></div>" end)

    html |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)
    # html |> EEx.compile_string(engine: Phoenix.LiveView.Engine, file: path, line: 1)
  end
end
