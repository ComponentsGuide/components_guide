defmodule ComponentsGuide.Wasm.Examples.HTTPHeaders do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.MemEql
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.StringHelpers
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  defmodule CacheControl do
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control

    use Wasm
    use BumpAllocator

    # @wasm_global {:private, i32(0)}
    # @wasm_global private: i32(0)
    # global private: i32(0)

    defwasm globals: [
              private: i32(0),
              public: i32(0),
              immutable: i32(0),
              max_age_seconds: i32(-1),
              s_max_age_seconds: i32(-1),
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

      func to_string(), result: I32.String, locals: [start: I32, byte_count: I32, int_offset: I32] do
        I32.when? private do
          const("private")
        else
          I32.when? public do
            I32.when? I32.ge_s(max_age_seconds, 0) do
              int_offset =
                byte_size("public, max-age=")
                |> I32.add(IntToString.u32toa_count(max_age_seconds))

              if immutable do
                byte_count = int_offset |> I32.add(byte_size(", immutable"))
              end

              # Add 1 for nul-byte
              start = alloc(I32.add(byte_count, 1))
              memcpy(start, const("public"), byte_size("public"))

              memcpy(
                I32.add(start, byte_size("public")),
                const(", max-age="),
                byte_size(", max-age=")
              )

              _ = IntToString.u32toa(max_age_seconds, I32.add(start, int_offset))

              # assert!(I32.eq(int_offset, 22))

              if immutable do
                memcpy(
                  start |> I32.add(int_offset),
                  const(", immutable"),
                  byte_size(", immutable")
                )
              end

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

  defmodule SetCookie do
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie

    use Wasm
    use BumpAllocator

    defwasm globals: [
              bump_offset: i32(BumpAllocator.bump_offset()),
              name: i32(0),
              value: i32(0),
              http_only: i32(0)
            ] do
      BumpAllocator.funcp(:bump_alloc)
      BumpAllocator.funcp(:bump_memcpy)
      StringHelpers.funcp(:strlen)
      IntToString.funcp(:u32toa_count)
      IntToString.funcp(:u32toa)

      func alloc(byte_count(I32)), result: I32 do
        call(:bump_alloc, byte_count)
      end

      func set_cookie_name(new_name(I32)) do
        name = new_name
      end

      func set_cookie_value(new_value(I32)) do
        value = new_value
      end

      func set_http_only() do
        http_only = 1
      end

      func to_string(),
        result: I32.String,
        locals: [start: I32, byte_count: I32, name_len: I32, value_len: I32, int_offset: I32] do
        name_len = call(:strlen, name)
        value_len = call(:strlen, value)
        byte_count = name_len |> I32.add(1) |> I32.add(value_len)

        # Add 1 for nul-byte
        start = alloc(I32.add(byte_count, 1))
        memcpy(start, name, name_len)
        memory32_8![I32.add(start, name_len)] = ?=

        memcpy(I32.add(1, I32.add(start, name_len)), value, value_len)

        # if immutable do
        #   memcpy(
        #     start |> I32.add(int_offset),
        #     const(", immutable"),
        #     byte_size(", immutable")
        #   )
        # end

        start
      end
    end
  end
end
