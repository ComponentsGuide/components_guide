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

  wasm_import(:datasource,
    load_repo_content_text:
      Orb.DSL.funcp(name: :load_repo_content_text, params: {I32.String}, result: I32.String),
    render_markdown_to_html:
      Orb.DSL.funcp(name: :render_markdown_to_html, params: {I32.String}, result: I32.String)
  )

  global :export_mutable do
    @repo_owner ""
    @repo_name ""
    @path "/"
  end
end
