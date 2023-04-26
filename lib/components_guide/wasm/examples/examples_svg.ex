defmodule ComponentsGuide.Wasm.Examples.SVG do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.MemEql

  defmodule Square do
    use Wasm

    defwasm imports: [
              env: [buffer: memory(2)]
            ],
            exported_mutable_globals: [
              color_hex: i32(0)
            ],
            globals: [
              body_chunk_index: i32(0)
            ] do
      func rewind do
      end

      func next_body_chunk, result: I32 do
        defblock Main, result: I32 do
          if I32.eq(body_chunk_index, 0) do
            const(~S[<svg width="64" height="64">])
            break(Main)
          end

          if I32.eq(body_chunk_index, 1) do
            const(~S[<rect width="64" height="64" fill="red" />])
            break(Main)
          end

          if I32.eq(body_chunk_index, 2) do
            const(~S[</svg>])
            break(Main)
          end

          0x0
        end

        body_chunk_index = I32.add(body_chunk_index, 1)
      end
    end

    def read_body(instance) do
      Instance.call_joining_string_chunks(:next_body_chunk, instance)
    end
  end
end
