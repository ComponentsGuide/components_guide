defmodule ComponentsGuide.Research.Spec do
  alias ComponentsGuide.Research.Source

  def search_for(:caniuse, query) when is_binary(query) do
    url = "https://cdn.jsdelivr.net/npm/caniuse-db@1.0.30001042/data.json"
    {:ok, data} = Source.json_at(url)
    table = data["data"]
    if false do
      keys = Map.keys(table)
      inspect(keys)
    else
      table["documenthead"] |> inspect()
    end
  end

  def search_for(:whatwg_html_spec, query) when is_binary(query) do
    IO.puts("searching whatwg html spec")

    # url = "https://html.spec.whatwg.org/"
    url = "https://html.spec.whatwg.org/dev/"

    # {:ok, html} = body({:fetch, url})
    # {:ok, html} = read({:fetch, url})
    {:ok, document} = Source.html_document_at(url)

    # IO.puts("document size #{:erts_debug.flat_size(document)}")

    # selector = css("#contents")
    # selector = xpath("//*[@id='contents']/following-sibling::ol[1]")
    # result = Meeseeks.one(document, selector)
    # Meeseeks.html(result)

    document
    |> Floki.find("body")
    |> Floki.find("a:fl-contains('form')")
    |> Floki.raw_html()

    # html
  end
end
