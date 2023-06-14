defmodule ComponentsGuide.Wasm.Examples.HTTPHeaders do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.MemEql
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  defmodule CacheControl do
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control

    use Wasm
    require BumpAllocator

    @page_size 64 * 1024
    @bump_start 1 * @page_size

    defwasm exported_memory: 2,
            globals: [
              private: i32(0),
              public: i32(0),
              immutable: i32(0),
              max_age_seconds: i32(-1),
              s_max_age_seconds: i32(-1),
              # bump_offset: i32(@bump_start)
              bump_offset: i32(BumpAllocator.bump_offset())
            ] do
      BumpAllocator.funcp(:bump_alloc)
      BumpAllocator.funcp(:bump_memcpy)
      IntToString.funcp(:u32toa_count)
      IntToString.funcp(:u32toa)

      func set_private() do
        private = 1
      end

      func set_public() do
        public = 1
      end

      func set_immutable() do
        immutable = 1
      end

      func set_max_age(age_seconds(I32)) do
        max_age_seconds = age_seconds
      end

      func set_s_max_age(age_seconds(I32)) do
        s_max_age_seconds = age_seconds
      end

      func to_string(), result: String, locals: [start: I32, byte_count: I32] do
        I32.when? private do
          const("private")
        else
          I32.when? public do
            I32.when? I32.ge_s(max_age_seconds, 0) do
              byte_count =
                byte_size("public, max-age=")
                |> I32.add(IntToString.u32toa_count(max_age_seconds))

              # Add 1 for nul-byte
              start = BumpAllocator.alloc(I32.add(byte_count, 1))
              BumpAllocator.memcpy(start, const("public"), byte_size("public"))

              BumpAllocator.memcpy(
                I32.add(start, byte_size("public")),
                const(", max-age="),
                byte_size(", max-age=")
              )

              _ = call(:u32toa, max_age_seconds, I32.add(start, byte_count))

              start
            else
              const("public")
            end
          else
            I32.when? immutable do
              const("immutable")
            else
              const("hello")
            end
          end
        end
      end
    end
  end
end
