defmodule ComponentsGuide.Research.Spec do
  alias ComponentsGuide.HTTPClient
  import Meeseeks.CSS
  import Meeseeks.XPath

  @cache_name :research_spec_cache

  defp read_cache(key) do
    value = Cachex.get(@cache_name, key)
    IO.puts("reading")
    IO.inspect(key)
    # IO.inspect(value)
    value
  end

  defp write_cache(key, value) do
    Cachex.put(@cache_name, key, value)
  end

  # defp fetch_url(url) when is_binary(url) do
  #   key = {:fetch, url}
  #   write_cache(key, :pending)
  #   result = HTTPClient.get(url)
  #   {:ok, response} = result
  #   html = response.body
  #   write_cache(key, {:html, html})
  #   html
  # end

  defp body({:fetch, url}) do
    result = HTTPClient.get(url)
    {:ok, response} = result
    html = response.body
    {:ok, html}
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

  # defp html_string_for_url(url) when is_binary(url) do
  #   with {:ok, result} <- read_cache({:fetch, url}),
  #        {:html, value} <- result do
  #     value
  #   else
  #     # Not in cache
  #     {:ok, nil} ->
  #       IO.puts("not in cache, fetching")
  #       # fetch_url(url)
  #       {:ok, html} = process({:fetch, url})
  #       write_cache({:fetch, url}, {:html, html})
  #       {:ok, html}

  #     _ ->
  #       :err
  #   end
  # end

  # defp html_document_for_url(url) when is_binary(url) do
    # case read_cache({:html_document, url}) do
    #   # Not in cache
    #   {:ok, nil} ->
    #     IO.puts("not in cache, parsing")
    #     html = html_string_for_url(url)
    #     document = Meeseeks.parse(html)
    #     # :crypto.hash(:sha256,"I love Elixir")
    #     write_cache({:html_document, url}, document)
    #     document

    #   {:ok, document} ->
    #     document

    #   _ ->
    #     nil
    # end
  # end

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
