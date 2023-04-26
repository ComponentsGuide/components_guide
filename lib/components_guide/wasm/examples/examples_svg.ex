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
              color_hex: i32(0x000000ff)
            ],
            globals: [
              body_chunk_index: i32(0)
            ] do
      cpfuncp(i32_to_hex_lower, from: HexConversion)

      func rewind do
        body_chunk_index = 0
      end

      func next_body_chunk, result: I32 do
        defblock Main, result: I32 do
          if I32.eq(body_chunk_index, 0) do
            const(~S[<svg width="64" height="64">])
            break(Main)
          end

          if I32.eq(body_chunk_index, 1) do
            const(~S[<rect width="64" height="64" fill="])
            break(Main)
          end

          if I32.eq(body_chunk_index, 2) do
            memory32_8![0x10000] = ?#
            call(:i32_to_hex_lower, color_hex, 0x10001)
            0x10000
            break(Main)
          end

          if I32.eq(body_chunk_index, 3) do
            const(~S[" />])
            break(Main)
          end

          if I32.eq(body_chunk_index, 4) do
            const(~S[</svg>\n])
            break(Main)
          end

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
