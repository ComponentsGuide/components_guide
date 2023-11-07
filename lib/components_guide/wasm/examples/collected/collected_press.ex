defmodule ComponentsGuide.Wasm.Examples.Collected.CollectedPress do
  # It will find Markdown file corresponding to input path, and load it.
  # It will load _head.html
  # It will load _nav.md
  # It will load _contentinfo.md
  # It will ask for them to be transformed into Markdown
  # It will combine them into one HTML stream.

  use Orb

  # defmodule URL do
  #   def wasm_type(), do: :i32
  # end

  # strings I32.StringStartAndLength

  I32.export_enum([:url_to_proxy_provided, :response_provided])

  defmodule Datasource do
    use Orb.Import

    defw(load_repo_content_text(path: I32.String, write_ptr: I32), I32)
    defw(render_markdown_to_html(markdown: I32.String, write_ptr: I32), I32)
  end

  importw(Datasource, :datasource)

  global :export_mutable do
    @repo_owner ""
    @repo_name ""
    @path "/"
  end
end
