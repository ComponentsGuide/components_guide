defmodule ComponentsGuide.Research.Spec do
  alias ComponentsGuide.Research.Source

  def caniuse(query) do
    %{
      source: {:json_url, "https://cdn.jsdelivr.net/npm/caniuse-db@1.0.30001142/data.json"},
      processor: {:caniuse, query}
    }
  end

  def npm_downloads_last_month(query) do
    query = String.trim(query)
    %{
      source: {:json_url, "https://api.npmjs.org/downloads/point/last-month/#{query}"},
      processor: {:npm_downloads, query}
    }
  end

  def whatwg_html_spec(query) do
    %{
      source: {:html_document_url, "https://html.spec.whatwg.org/dev/"},
      processor: {:whatwg_html_spec, query}
    }
  end

  def search_for(:caniuse, query) when is_binary(query) do
    url = "https://cdn.jsdelivr.net/npm/caniuse-db@1.0.30001142/data.json"
    result = Source.json_at(url)
    IO.inspect(result)
    process_search_for(:caniuse, query, result)
  end

  def search_for(:npm_downloads_last_month, query) when is_binary(query) do
    query = String.trim(query)
    url = "https://api.npmjs.org/downloads/point/last-month/#{query}"

    case Source.json_at(url) do
      {:ok, %{"downloads" => downloads_count, "package" => name}} ->
        %{downloads_count: downloads_count, name: name}

      {:ok, %{"error" => _error_message}} ->
        nil

      _ ->
        nil
    end
  end

  def search_for(:whatwg_html_spec, query) when is_binary(query) do
    # url = "https://html.spec.whatwg.org/"
    url = "https://html.spec.whatwg.org/dev/"

    case Source.html_document_at(url) do
      {:ok, document} ->
        document
        |> Floki.find("body")
        |> Floki.find("a:fl-contains('#{query}')")
        |> Floki.raw_html()

      _ ->
        ""
    end
  end

  def search_for(:html_aria_spec, query) when is_binary(query) do
    url = "https://www.w3.org/TR/html-aria/"
    result = Source.html_document_at(url)
    process_search_for(:html_aria_spec, query, result)
  end

  def search_for(:wai_aria_practices, query) when is_binary(query) do
    url = "https://www.w3.org/TR/wai-aria-practices/"
    # TODO replace with "https://www.w3.org/WAI/ARIA/apg/example-index/"
    result = Source.html_document_at(url)
    process_search_for(:wai_aria_practices, query, result)
  end

  def search_for(:bundlephobia, query) when is_binary(query) do
    case Source.json_at("https://bundlephobia.com/api/size?package=#{query}") do
      {:ok, data} ->
        data

      _ ->
        nil
    end
  end

  defp process_search_for(:caniuse, query, {:ok, %{"data" => table}})
       when is_binary(query) and is_map(table) do
    query = query |> String.trim() |> String.downcase()

    table
    |> Stream.filter(fn {_key, value} ->
      value["keywords"] |> String.contains?(query) ||
        value["title"] |> String.downcase() |> String.contains?(query) ||
        value["description"] |> String.downcase() |> String.contains?(query)
    end)
    |> Enum.map(fn {_key, value} -> value end)
  end

  defp process_search_for(:wai_aria_practices, query, {:ok, document}) when is_binary(query) do
    html_elements = document |> Floki.find("[id*='#{query}']")

    results =
      Enum.map(html_elements, fn el ->
        heading = Floki.find(el, "h1, h2, h3, h4")

        %{
          heading: heading |> Floki.text(),
          html: el
        }
      end)

    results

    # document
    # # |> Floki.find("#toc li a")
    # # |> Floki.find("[href*='#{query}']")
    # |> Floki.find("[id*='#{query}']")
    # |> Floki.raw_html()
  end

  defp process_search_for(:html_aria_spec, query, {:ok, document}) do
    html_elements =
      document
      |> Floki.find(
        "#document-conformance-requirements-for-use-of-aria-attributes-in-html table tbody"
      )
      |> Floki.find("tr")

    # |> Floki.find("[id*='#{query}']")
    # |> Floki.find("tr:fl-contains('#{query}')")

    html_elements =
      Enum.filter(html_elements, fn
        el = {"tr", _attrs, _children} ->
          Floki.text(el) |> String.contains?(query)

        _ ->
          false
      end)

    # html_elements =
    #   Floki.traverse_and_update(html_elements, fn
    #     el = {"tr", _attrs, _children} ->
    #       case Floki.text(el) |> String.contains?(query) do
    #         true -> el
    #         false -> nil
    #       end

    #     el ->
    #       el
    #   end)

    results =
      Enum.map(html_elements, fn el ->
        html_feature = Floki.find(el, "td:first-of-type")
        implicit_semantics = Floki.find(el, "td:nth-of-type(2)")

        %{
          heading: html_feature |> Floki.text(),
          implicit_semantics: implicit_semantics |> Floki.text(),
          html: el
        }
      end)
  end

  defp process_search_for(_id, _query, _), do: []
end
