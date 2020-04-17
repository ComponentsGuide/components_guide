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
      matching_keywords =
        table
        |> Enum.flat_map(fn {key, value} ->
          case value["keywords"] |> String.contains?(query) do
            true -> [value["description"]]
            false -> []
          end
        end)

      # table["documenthead"] |> inspect()
      matching_keywords
    end
  end

  def search_for(:whatwg_html_spec, query) when is_binary(query) do
    # url = "https://html.spec.whatwg.org/"
    url = "https://html.spec.whatwg.org/dev/"

    {:ok, document} = Source.html_document_at(url)

    document
    |> Floki.find("body")
    |> Floki.find("a:fl-contains('#{query}')")
    |> Floki.raw_html()
  end

  def search_for(:html_aria_spec, query) when is_binary(query) do
    url = "https://www.w3.org/TR/html-aria/"
    {:ok, document} = Source.html_document_at(url)

    document
    |> Floki.find("#document-conformance-requirements-for-use-of-aria-attributes-in-html table tbody tr")
    # |> Floki.find("#id-#{query}")
    |> Floki.raw_html()
  end

  def search_for(:bundlephobia, query) when is_binary(query) do
    {:ok, data} = Source.json_at("https://bundlephobia.com/api/size?package=#{query}")

    inspect(data)
  end
end
