defmodule ComponentsGuide.Wasm.Examples.HTTPHeaders do
  alias ComponentsGuide.Wasm.Examples.StringBuilder

  defmodule CacheControl do
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
    # https://developers.cloudflare.com/cache/concepts/cache-control/
    # https://bitsup.blogspot.com/2016/05/cache-control-immutable.html
    # https://hacks.mozilla.org/2017/01/using-immutable-caching-to-speed-up-the-web/
    # https://github.com/jjenzz/pretty-cache-header

    use Orb
    use SilverOrb.BumpAllocator
    use SilverOrb.Mem
    use StringBuilder

    def start(), do: OrbWasmtime.Instance.run(__MODULE__)

    I32.global(
      private: false,
      public: false,
      no_store: false,
      immutable: false,
      max_age_seconds: -1,
      s_max_age_seconds: -1
    )

    wasm S32 do
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

      func set_max_age(age_seconds: I32) do
        @max_age_seconds = age_seconds
      end

      func set_shared_max_age(age_seconds: I32) do
        @s_max_age_seconds = age_seconds
      end

      func to_string(), I32.String do
        build! do
          if @public do
            append!(~S|public|)
          else
            if @private do
              append!(~S|private|)
            else
              if @no_store do
                append!(~S|no-store|)
              end
            end
          end

          if @max_age_seconds > 0 do
            if appended?(), do: append!(~S|, |)

            append!(~S|max-age=|)
            append!(decimal_u32: @max_age_seconds)
          end

          if @s_max_age_seconds > 0 do
            if appended?(), do: append!(~S|, |)

            append!(~S|s-maxage=|)
            append!(decimal_u32: @s_max_age_seconds)
          end

          if @immutable do
            if appended?(), do: append!(~S|, |)

            append!(~S|immutable|)
          end

          if not(appended?()) do
            append!(~S|max-age=0|)
          end

        end
      end
    end
  end

  defmodule SetCookie do
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie

    use Orb
    use SilverOrb.BumpAllocator
    use SilverOrb.Mem
    use I32.String
    use StringBuilder

    SilverOrb.BumpAllocator.export_alloc()

    # defmodule Constants do
    #   @constant_values I32.calculate_enum([:secure, :http_only])

    #   def get_len(value) do

    #   end
    # end

    I32.global(
      name: 0,
      value: 0,
      domain: 0,
      path: 0,
      secure: false,
      http_only: false
    )

    wasm U32 do
      I32.attr_writer(:name, as: :set_cookie_name)
      I32.attr_writer(:value, as: :set_cookie_value)
      I32.attr_writer(:domain, as: :set_domain)
      I32.attr_writer(:path, as: :set_path)

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

        # TODO: remove all this len stuff
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

        build! do
          append!(string: @name)
          append!(ascii: ?=)
          append!(string: @value)

          if domain_len do
            append!(string: const("; Domain="))
            append!(string: @domain)
          end

          if path_len do
            append!(string: const("; Path="))
            append!(string: @path)
          end

          if @secure do
            append!(string: const("; Secure"))
          end

          if @http_only do
            append!(string: const("; HttpOnly"))
          end
        end
      end
    end
  end

  defmodule SimpleHeader do
    # TODO: Implement this algorithm: https://fetch.spec.whatwg.org/#simple-header
  end
end
