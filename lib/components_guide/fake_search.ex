defmodule ComponentsGuide.FakeSearch do
  alias ComponentsGuide.Fetch

  def list() do
    response = Fetch.get_following_redirects!("https://jsonplaceholder.typicode.com/posts")
    data = Jason.decode!(response.body)
    data
  end
end
