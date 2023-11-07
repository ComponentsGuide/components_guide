defmodule ComponentsGuide.Wasm.Examples.Favicon.FaviconGenerator do
  # You supply a PNG? SVG? And it gets converted to the image/vnd.microsoft.icon format.
  # Or you can draw basic shapes that get rasterized?
  # https://docs.fileformat.com/image/ico/

  @ico_header <<0x00000100::16>> <> <<0x0400::16>>

  def image_header(width, height) do
    0x10100000_01002000_28050000
  end
end
