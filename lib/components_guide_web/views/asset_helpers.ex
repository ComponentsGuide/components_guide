defmodule ComponentsGuideWeb.AssetsHelpers do
  @moduledoc """
  Conveniences for presenting assets like images
  """

  use Phoenix.HTML
  import Phoenix.View
  alias ComponentsGuideWeb.Router.Helpers, as: Routes

  def collected_image(conn, module, image_name) do
    %{static_path: path_to_image, width: width, height: height} = module.render(image_name, [])
    url = Routes.static_path(conn, "/" <> path_to_image)
    tag(:img, src: url, width: width / 2, height: height / 2)
  end

  def collected_figure(conn, module, image_name, caption) do
    content_tag(:figure, [
      collected_image(conn, module, image_name),
      content_tag(:figcaption, caption)
    ])
  end
end
