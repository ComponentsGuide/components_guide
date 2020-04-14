defmodule ComponentsGuide.Research.Spec do
  alias ComponentsGuide.HTTPClient
  import Meeseeks.CSS
  import Meeseeks.XPath

  @cache_name :research_spec_cache

  defp read_cache(key) do
    value = Cachex.get(@cache_name, key)
    IO.puts("reading #{if value == nil, do: "nil", else: "present"}")
    IO.inspect(key)
    value
  end

  defp write_cache(key, value) do
    Cachex.put(@cache_name, key, value)
  end

  defp body({:fetch, url}) do
    with {:ok, response} <- HTTPClient.get(url) do
      html = response.body
      {:ok, html}
    end
  end

  defp body({:html_document, url}) do
    {:ok, html} = read({:fetch, url})
    document = Meeseeks.parse(html)
    {:ok, document}
  end

  defp run(key) do
    tuple = {:ok, value} = body(key)
    write_cache(key, value)
    tuple
  end

  defp read(key) do
    case read_cache(key) do
      {:ok, nil} ->
        run(key)

      {:ok, value} ->
        {:ok, value}

      other ->
        other
    end
  end

  def clear_search_cache() do
    Cachex.clear(@cache_name)
  end

  def search_for(:whatwg_html_spec, query) when is_binary(query) do
    IO.puts("searching whatwg html spec")
    {:ok, document} = read({:html_document, "https://html.spec.whatwg.org/"})

    # selector = css("#contents")
    selector = xpath("//*[@id='contents']/following-sibling::ol[1]")
    result = Meeseeks.one(document, selector)
    Meeseeks.html(result)
  end
end
