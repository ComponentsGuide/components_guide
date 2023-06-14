defmodule ComponentsGuide.Wasm.Examples.HTTPHeaders do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.MemEql
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

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
              bump_offset: i32(@bump_start)
              # bump_offset: i32(BumpAllocator.bump_offset())
            ] do
      BumpAllocator.funcp(:bump_alloc)
      BumpAllocator.funcp(:bump_memcpy)

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

      func to_string(), result: String, locals: [start: I32, digit: I32] do
        if private, result: I32 do
          const("private")
        else
          if public, result: I32 do
            start = call(:bump_alloc, byte_size("public") + 1)
            # start = call(:bump_alloc, 7)
            # call(:bump_memcpy, start, const("public"), 6)
            # start = BumpAllocator.alloc(byte_size("public") + 1)
            BumpAllocator.memcpy(start, const("public"), 6)
            # memory32_8![start] = ?p
            # memory32_8![I32.add(start, 1)] = ?u
            # memory32_8![I32.add(start, 2)] = ?b
            # const("public")
            start
          else
            if immutable, result: I32 do
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
