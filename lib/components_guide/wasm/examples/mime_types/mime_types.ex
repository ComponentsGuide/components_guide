# Compare to Zig version compiled to WebAssembly:
# https://github.com/andrewrk/mime

defmodule ComponentsGuide.Wasm.Examples.MimeTypes do
  use Orb

  require SilverOrb.Arena |> alias

  Arena.def(Heap, pages: 1)
  # Heap.export_alloc()

  # defw get_mime_type_for_extension(extension: Heap.String), Heap.String do

  # end
end
