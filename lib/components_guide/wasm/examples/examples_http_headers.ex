defmodule ComponentsGuide.Wasm.Examples.HTTPHeaders do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Writer
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.Copying
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  defmodule CacheControl do
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
    # https://developers.cloudflare.com/cache/concepts/cache-control/
    # https://bitsup.blogspot.com/2016/05/cache-control-immutable.html
    # https://hacks.mozilla.org/2017/01/using-immutable-caching-to-speed-up-the-web/
    # https://github.com/jjenzz/pretty-cache-header

    use Wasm
    use BumpAllocator
    use Copying
    import Writer

    def start(), do: Wasm.Instance.run(__MODULE__)

    I32.global(
      private: false,
      public: false,
      no_store: false,
      immutable: false,
      max_age_seconds: -1,
      s_max_age_seconds: -1
    )

    wasm do
      IntToString.funcp(:u32toa_count)
      IntToString.funcp(:write_u32)

      func set_private() do
        @private = 1
      end

      func set_public() do
        @public = 1
      end

      func set_no_store() do
        @no_store = 1
      end

      func set_immutable() do
        @immutable = 1
      end

      func set_max_age(age_seconds(I32)) do
        @max_age_seconds = age_seconds
      end

      func set_shared_max_age(age_seconds(I32)) do
        @s_max_age_seconds = age_seconds
      end

      func to_string(),
           I32.String,
           # globals: [public: I32],
           writer: I32,
           start: I32 do
        start = alloc(500)
        writer = start

        if @public do
          write!(const("public"))
        else
          # if private do
          if global_get(:private) do
            write!(const("private"))
          else
            if @no_store do
              write!(const("no-store"))
            end
          end
        end

        if I32.ge_s(@max_age_seconds, 0) do
          if I32.gt_u(writer, start) do
            write!(const(", "))
          end

          write!(const("max-age="))
          write!(u32: @max_age_seconds)
        end

        if I32.ge_s(@s_max_age_seconds, 0) do
          if I32.gt_u(writer, start) do
            write!(const(", "))
          end

          write!(const("s-maxage="))
          write!(u32: @s_max_age_seconds)
        end

        if @immutable do
          if I32.gt_u(writer, start) do
            write!(const(", "))
          end

          write!(const("immutable"))
        end

        if I32.eq(writer, start) do
          write!(const("max-age=0"))
        end

        start
      end
    end
  end

  defmodule SetCookie do
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie

    use Wasm
    # use Memory, allocator: :bump
    use BumpAllocator
    use Copying
    use I32.String
    import Writer

    # defmodule Constants do
    #   @constant_values I32.calculate_enum([:secure, :http_only])

    #   def get_len(value) do

    #   end
    # end

    global(
      name: I32.String.null(),
      value: I32.String.null(),
      domain: I32.String.null(),
      path: I32.String.null(),
      secure: i32_boolean(0),
      http_only: i32_boolean(0)
    )

    wasm U32 do
      IntToString.funcp(:u32toa_count)
      IntToString.funcp(:u32toa)

      func(alloc(byte_count: I32), I32, do: call(:bump_alloc, byte_count))

      I32.prop(:name, as: :set_cookie_name)
      I32.prop(:value, as: :set_cookie_value)
      I32.prop(:domain, as: :set_domain)
      I32.prop(:path, as: :set_path)

      # func set_cookie_value(new_value(I32.String)) do
      #   value = new_value
      # end

      # I32.Boolean.attr_one_way(:secure, as: :set_secure)

      func set_secure() do
        @secure = 1
      end

      func set_http_only() do
        @http_only = 1
      end

      func to_string(),
           I32.String,
           str: I32,
           byte_count: I32,
           writer: I32,
           name_len: I32,
           value_len: I32,
           domain_len: I32,
           path_len: I32,
           extra_len: I32 do
        name_len = strlen(@name)
        value_len = strlen(@value)
        domain_len = strlen(@domain)
        path_len = strlen(@path)

        extra_len =
          I32.sum!([
            I32.when?(domain_len > 0, do: I32.add(domain_len, byte_size("; Domain=")), else: 0),
            I32.when?(path_len > 0, do: I32.add(path_len, byte_size("; Path=")), else: 0),
            I32.when?(@secure, do: byte_size("; Secure"), else: 0),
            I32.when?(@http_only, do: byte_size("; HttpOnly"), else: 0)
          ])

        byte_count = I32.sum!([name_len, 1, value_len, extra_len])

        # TODO: replace with build!/1
        # Add 1 for nul-terminator
        str = alloc(I32.add(byte_count, 1))
        writer = str

        write!(@name, name_len)
        write!(ascii: ?=)
        write!(@value, value_len)

        if domain_len do
          write!(const("; Domain="))
          write!(@domain, domain_len)
        end

        if path_len do
          write!(const("; Path="))
          write!(@path, path_len)
        end

        if @secure do
          write!(const("; Secure"))
        end

        if @http_only do
          write!(const("; HttpOnly"))
        end

        assert!(I32.eq(writer, I32.add(str, byte_count)))

        str
      end
    end
  end

  defmodule SimpleHeader do
    # TODO: Implement this algorithm: https://fetch.spec.whatwg.org/#simple-header
  end
end
