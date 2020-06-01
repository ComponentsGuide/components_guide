defmodule ComponentsGuideWeb.MarkdownEngine do
  @moduledoc false

  @behaviour Phoenix.Template.Engine

  require Earmark

  def compile(path, _name) do
    IO.puts("compile #{path}")
    path
    |> File.read!()
    |> Earmark.as_html!(%Earmark.Options{code_class_prefix: "language-", smartypants: false})
    |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)
  end
end
