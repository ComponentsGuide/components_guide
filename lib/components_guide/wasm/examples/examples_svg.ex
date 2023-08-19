defmodule ComponentsGuide.Wasm.Examples.SVG do
  alias OrbWasmtime.Instance
  alias ComponentsGuide.Wasm.Examples.Parser.HexConversion

  defmodule Square do
    use Orb

    Memory.pages(2)

    I32.export_global(:mutable,
      # Opaque black
      color_hex: 0x000000FF
    )

    I32.global(body_chunk_index: 0)

    wasm do
      HexConversion.funcp(:u32_to_hex_lower)

      func rewind do
        @body_chunk_index = 0
      end

      func next_body_chunk(), I32.String do
        I32.match @body_chunk_index do
          0 ->
            ~S[<svg width="64" height="64">]

          1 ->
            ~S[<rect width="64" height="64" fill="]

          2 ->
            memory32_8![0x10000] = ?#
            HexConversion.u32_to_hex_lower(@color_hex, 0x10001)
            push(0x10000)

          3 ->
            ~S[" />]

          4 ->
            ~S[</svg>\n]

          _ ->
            0x0
        end

        @body_chunk_index = I32.add(@body_chunk_index, 1)
      end
    end

    def read_body(instance) do
      Instance.call_joining_string_chunks(instance, :next_body_chunk)
    end
  end
end
