defmodule ComponentsGuideWeb.TemplateEngines.MarkdownEngine do
  @moduledoc false

  @behaviour Phoenix.Template.Engine

  require Earmark

  def compile(path, name) do
    IO.puts("compile #{path} #{name}")

    html =
      path
      |> File.read!()
      |> Earmark.as_html!(%Earmark.Options{code_class_prefix: "language-", smartypants: false})
      # |> Earmark.as_html!(%Earmark.Options{code_class_prefix: "language-", smartypants: false, postprocessor: &map_ast/1})

    # regex = ~r{<live-([\w-]+)>(.+)</live-([\w-]+)>}
    regex = ~r{<live-([\w-]+)>([^<]+)</live-([^>]+)>}
    # regex = ~r{<live-([\w-]+)>}

    html =
      Regex.replace(regex, html, fn whole, tag_suffix, content ->
        case tag_suffix do
          "render" ->
            # |> String.to_existing_atom
            module = content |> String.trim()
            "<div><%= live_render(@conn, #{module}, session: %{}) %></div>"

          "component" ->
            # |> String.to_existing_atom
            module = content |> String.trim()
            "<div><%= live_component(@conn, #{module}) %></div>"

          _ ->
            "!" <> name <> "!" <> content
        end
      end)

    regex = ~r{<collected-([\w-]+) image="([^"]+)">([^<]+)</collected-([^>]+)>}

    html =
      Regex.replace(regex, html, fn _whole, tag_suffix, image, content ->
        case tag_suffix do
          "figure" ->
            "<div><%= collected_figure(@conn, #{inspect(image)}, #{inspect(content)}) %></div>"

          _ ->
            "!" <> image <> "!" <> content
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

  # defp map_ast({"h2", attrs, content, options}), do: {"h2", [class: "red"], content, %{class: "blue"}}
  # defp map_ast(input), do: IO.inspect(input, label: "ast")
end
