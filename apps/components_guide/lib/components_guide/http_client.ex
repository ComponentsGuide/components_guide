defmodule ComponentsGuide.HTTPClient do
  use Tesla #, only: [:get]

  plug Tesla.Middleware.FollowRedirects, max_redirects: 3
  plug Tesla.Middleware.Timeout, timeout: 30_000

end
