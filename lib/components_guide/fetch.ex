defmodule ComponentsGuide.Fetch do
  alias __MODULE__.{Get, Request}

  def get!(url_string) when is_binary(url_string) do
    Get.get_following_redirects!(url_string)
  end

  def load!(%Request{} = request) do
    Get.load!(request)
  end
end
