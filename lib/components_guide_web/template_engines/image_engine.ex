defmodule ComponentsGuideWeb.TemplateEngines.ImageEngine do
  @moduledoc false

  @behaviour Phoenix.Template.Engine

  require ExImageInfo

  def compile(path, _name) do
    data = File.read!(path)

    media_type = MIME.from_path(path)
    hash = :crypto.hash(:sha256, data)
    hash_base64 = hash |> Base.url_encode64()
    extension = MIME.extensions(media_type) |> List.first()
    static_path = Path.join(["collected", media_type, "#{hash_base64}.#{extension}"])

    image_info_type =
      case media_type do
        "image/png" -> :png
      end

    {_, width, height, _} = ExImageInfo.info(data, image_info_type)

    result = %{
      source_path: path,
      static_path: static_path,
      width: width,
      height: height
    }

    Macro.escape(result)
  end
end
