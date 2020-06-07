defmodule Mix.Tasks.TemplateAssets do
  use Mix.Task

  alias ComponentsGuideWeb.Endpoint

  @shortdoc "Move images from templates to static assets"
  def run(_) do
    Mix.Task.run("app.start")

    image_paths = Path.wildcard(Path.join(templates_path(), "/**/*.{png,jpg,jpeg,gif}"))
    for image_path <- image_paths do
      process_image(image_path)
    end

    # templates_path = Application.app_dir(:components_guide_web, "templates")
    # Application.app_dir(:components_guide_web, "priv")

    count = Enum.count(image_paths)

    Mix.shell().info("Processed #{count} file(s).")
  end

  defp project_dir(), do: File.cwd!
  defp templates_path(), do: Path.join(project_dir(), "/apps/components_guide_web/lib/components_guide_web/templates")
  defp static_collected_dir(), do: Path.join(project_dir(), "/apps/components_guide_web/priv/static/collected")

  defp process_image(image_path) do
    data = File.read!(image_path)
    media_type = MIME.from_path(image_path)
    hash = :crypto.hash(:sha256, data)
    hash_base64 = hash |> Base.url_encode64()
    destination_dir = Path.join(static_collected_dir(), media_type)
    File.mkdir_p!(destination_dir)
    extension = MIME.extensions(media_type) |> List.first()
    destination_path = Path.join(destination_dir, "#{hash_base64}.#{extension}")
    File.copy!(image_path, destination_path)
    Mix.shell().info("Copied #{image_path} to #{destination_path}")
  end
end
