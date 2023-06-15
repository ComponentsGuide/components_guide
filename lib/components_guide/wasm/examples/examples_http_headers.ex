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

    dbg("set global")
    @wasm_global {:private2, i32(0)}
    # @wasm_global private: i32(0)
    # global private: i32(0)

    defwasm globals: [
              private: i32_boolean(0),
              public: i32_boolean(0),
              immutable: i32_boolean(0),
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
    import StringHelpers

    # defmodule Constants do
    #   @constant_values I32.enum([:secure, :http_only])

    #   def get_len(value) do

    #   end
    # end

    defp write!(src, byte_count) do
      snippet writer: I32 do
        memcpy(writer, src, byte_count)
        writer = I32.add(writer, byte_count)
      end
    end

    defp write!({:i32_const_string, src_ptr, string}) do
      byte_count = byte_size(string)

      snippet writer: I32 do
        memcpy(writer, src_ptr, byte_count)
        writer = I32.add(writer, byte_count)
      end
    end

    defp write!(char) do
      snippet writer: I32 do
        memory32_8![writer] = char
        writer = I32.add(writer, 1)
      end
    end

    defwasm globals: [
              bump_offset: i32(BumpAllocator.bump_offset()),
              name: i32_null_string(),
              value: i32_null_string(),
              domain: i32_null_string(),
              secure: i32_boolean(0),
              http_only: i32_boolean(0)
            ] do
      BumpAllocator.funcp(:bump_alloc)
      BumpAllocator.funcp(:bump_memcpy)
      StringHelpers.funcp(:strlen)
      IntToString.funcp(:u32toa_count)
      IntToString.funcp(:u32toa)

      func alloc(byte_count(I32)), I32 do
        call(:bump_alloc, byte_count)
      end

      func set_cookie_name(new_name(I32.String)) do
        name = new_name
      end

      func set_cookie_value(new_value(I32.String)) do
        value = new_value
      end

      func set_domain(new_value(I32.String)) do
        domain = new_value
      end

      func set_secure() do
        secure = 1
      end

      func set_http_only() do
        http_only = 1
      end

      func to_string(),
           I32.String,
           str: I32,
           byte_count: I32,
           writer: I32,
           name_len: I32,
           value_len: I32,
           domain_len: I32,
           extra_len: I32 do
        name_len = strlen(name)
        value_len = strlen(value)
        domain_len = strlen(domain)

        extra_len =
          I32.add([
            I32.when?(domain_len, do: I32.add(domain_len, byte_size("; Domain=")), else: 0),
            I32.when?(secure, do: byte_size("; Secure"), else: 0),
            I32.when?(http_only, do: byte_size("; HttpOnly"), else: 0)
          ])

        byte_count = I32.add([name_len, 1, value_len, extra_len])

        # Add 1 for nul-byte
        str = alloc(I32.add(byte_count, 1))
        writer = str

        write!(name, name_len)
        write!(?=)
        write!(value, value_len)

        if domain_len do
          write!(const("; Domain="))
          write!(domain, domain_len)
        end

        if secure do
          write!(const("; Secure"))
        end

        if http_only do
          write!(const("; HttpOnly"))
        end

        assert!(I32.eq(writer, I32.add(str, byte_count)))

        str
      end
    end
  end
end
