defmodule ComponentsGuide.FetchTest do
  use ExUnit.Case, async: true

  # doctest ComponentsGuide.Fetch

  test "can fetch news.ycombinator.com" do
    response = ComponentsGuide.Fetch.get!("https://news.ycombinator.com/")

    assert %ComponentsGuide.Fetch.Response{
             done?: true,
             url: "https://news.ycombinator.com/",
             status: 200,
             headers: _,
             body: _
           } = response
  end

  test "can load HEAD for news.ycombinator.com" do
    response =
      ComponentsGuide.Fetch.load!(
        ComponentsGuide.Fetch.Request.new!("https://news.ycombinator.com/", method: "HEAD")
      )

    assert %ComponentsGuide.Fetch.Response{
             done?: true,
             url: "https://news.ycombinator.com/",
             status: _,
             headers: _,
             body: _
           } = response

    content_type =
      Enum.find_value(response.headers, fn
        {"content-type", value} -> value
        _ -> nil
      end)
    assert "text/html" == content_type
  end
end
