defmodule ComponentsGuide.FakeSearch do
  defp get_url(url) do
    HTTPotion.get(url, follow_redirects: true)
  end

  def list() do
    response = get_url("https://jsonplaceholder.typicode.com/posts")
    data = Jason.decode!(response.body)
    data
  end
end
