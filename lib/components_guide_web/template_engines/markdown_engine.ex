defmodule ComponentsGuideWeb.TemplateEngines.MarkdownEngine do
  @moduledoc false

  @behaviour Phoenix.Template.Engine

  require Earmark

  def slug(text) do
    slug =
      text
      |> String.downcase()
      |> String.replace(~w{ , ` - – — / { \} [ ] ; : ? !}, "")
      |> String.replace(" ", "-")

    slug
    # "-md-" <> slug
  end

  def h2_add_slug_processor(node) do
    html_fragment = Earmark.Transform.transform([node])
    inner_text = Floki.parse_fragment!(html_fragment) |> Floki.text() |> String.trim()
    id = slug(inner_text)

    node
    |> Earmark.AstTools.merge_atts_in_node(id: slug(inner_text))
  end

  def compile(path, name) do
    IO.puts("compile #{path} #{name}")

    registered_processors = [
      {"h2", &h2_add_slug_processor/1}
    ]

    # |> Earmark.TagSpecificProcessors.new()

    options =
      Earmark.Options.make_options!(
        code_class_prefix: "language-",
        smartypants: false,
        registered_processors: registered_processors
      )

    file_contents = File.read!(path)

    {front_matter, markdown} =
      case file_contents do
        "---\n---\n" <> markdown ->
          {nil, markdown}

        "---\n" <> rest ->
          [front_matter, markdown] = String.split(rest, "\n---\n", parts: 2)
          {front_matter, markdown}

        markdown ->
          {nil, markdown}
      end


    # |> Earmark.as_html!(%Earmark.Options{code_class_prefix: "language-", smartypants: false, postprocessor: &map_ast/1})

    # html = Regex.replace(regex, html, fn whole, name, content -> "!" <> name <> "!" <> content end)

    # html = Regex.replace(regex, html, fn whole, name, content -> "<div><%= live_render(@conn, ComponentsGuideWeb.FakeSearchLive, session: %{}) %></div>" end)

    case front_matter do
      nil ->
        html = Earmark.as_html!(markdown, options)
        html = todo_remove_old_custom_elements(html, name)
        html |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)

      s ->
        html = Earmark.as_html!(markdown, options)
        quote do
          unquote(Code.string_to_quoted!(s, file: path))

          unquote(
            html
            |> EEx.compile_string(engine: Phoenix.LiveView.HTMLEngine, file: path, line: 1)
          )
        end
    end

    # TODO: use Heex?
    # unless Macro.Env.has_var?(__CALLER__, {:assigns, nil}) do
    #   raise "~H requires a variable named \"assigns\" to exist and be set to a map"
    # end

    # options = [
    #   engine: Phoenix.LiveView.HTMLEngine,
    #   file: __CALLER__.file,
    #   line: __CALLER__.line + 1,
    #   module: __CALLER__.module,
    #   indentation: meta[:indentation] || 0
    # ]

    # EEx.compile_string(expr, options)

    # case live? do
    #   true ->
    #     html |> EEx.compile_string(engine: Phoenix.HTML.Engine, file: path, line: 1)

    #   false ->

    # end
    # html |> EEx.compile_string(engine: Phoenix.LiveView.Engine, file: path, line: 1)
  end

  defp todo_remove_old_custom_elements(html, name) do
    # regex = ~r{<live-([\w-]+)>(.+)</live-([\w-]+)>}
    regex = ~r{<live-([\w-]+)>([^<]+)</live-([^>]+)>}
    # regex = ~r{<live-([\w-]+)>}

    html =
      Regex.replace(regex, html, fn _whole, tag_suffix, content ->
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
            # "<div><%= inspect(__MODULE__) %></div>"
            "<div><%= collected_figure(@conn, __MODULE__, #{inspect(image)}, #{inspect(content)}) %></div>"

          _ ->
            "!" <> image <> "!" <> content
        end
      end)

    html
  end

  # defp map_ast({"h2", attrs, content, options}), do: {"h2", [class: "red"], content, %{class: "blue"}}
  # defp map_ast(input), do: IO.inspect(input, label: "ast")
end
