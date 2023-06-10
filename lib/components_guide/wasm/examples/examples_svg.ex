defmodule ComponentsGuide.Wasm.Examples.SVG do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.MemEql
  alias ComponentsGuide.Wasm.Examples.Parser.HexConversion

  defmodule Square do
    use Wasm

    defwasm imports: [
              env: [buffer: memory(2)]
            ],
            exported_mutable_globals: [
              color_hex: i32(0x000000FF)
            ],
            globals: [
              body_chunk_index: i32(0)
            ] do
      cpfuncp(i32_to_hex_lower, from: HexConversion)

      func rewind do
        body_chunk_index = 0
      end

      func next_body_chunk, result: I32 do
        I32.match body_chunk_index do
          0 ->
            const(~S[<svg width="64" height="64">])

          1 ->
            const(~S[<rect width="64" height="64" fill="])

          2 ->
            memory32_8![0x10000] = ?#
            call(:i32_to_hex_lower, color_hex, 0x10001)
            push(0x10000)

          3 ->
            const(~S[" />])

          4 ->
            const(~S[</svg>\n])

          _ ->
            0x0
        end

        body_chunk_index = I32.add(body_chunk_index, 1)
      end
    end

    def read_body(instance) do
      Instance.call_joining_string_chunks(instance, :next_body_chunk)
    end
  end
end
