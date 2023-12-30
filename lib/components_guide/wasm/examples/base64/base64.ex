defmodule ComponentsGuide.Wasm.Base64 do
  # Accepts compile-time arguments:
  # - URL-safe or not
  # - Padding
  #
  # This will output different WebAssembly code, effectively “tree-shaking” the pieces of
  # code that are unused. It also removes branching (“is url-safe or not”) and optimized the size.
  #
  # Orb.defcomptimeflag :url_safe?, true
  # Orb.defcomptimeflag :padding?, true
end
