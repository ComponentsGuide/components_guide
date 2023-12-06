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

    defw set_private() do
      # @privacy = Privacy.private()
      @private = 1
    end

    defw set_public() do
      @public = 1
    end

    defw set_no_store() do
      @no_store = 1
    end

    defw set_immutable() do
      @immutable = 1
    end

    defw set_max_age(age_seconds: 0..100_000_000) do
      @max_age_seconds = age_seconds
    end

    defw set_shared_max_age(age_seconds: 0..100_000_000) do
      @s_max_age_seconds = age_seconds
    end

    defw to_string(), I32.String do
      build! do
        if @public do
          "public"
        else
          if @private do
            "private"
          else
            if @no_store do
              "no-store"
            end
          end
        end

        # cond do
        #   @public -> "public"
        #   @private -> "private"
        #   @no_store -> "no-store"
        #   true -> _
        # end

        if @max_age_seconds > 0 do
          if appended?(), do: ", "

          "max-age="
          append!(decimal_u32: @max_age_seconds)
        end

        if @s_max_age_seconds > 0 do
          if appended?(), do: ", "

          "s-maxage="
          append!(decimal_u32: @s_max_age_seconds)
        end

        if @immutable do
          if appended?(), do: ", "

          "immutable"
        end

        if not appended?() do
          "max-age=0"
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

    global do
      @name ""
      @value ""
      @domain ""
      @path ""
      @secure 0
      @http_only 0
    end

    defw set_cookie_name(new_value: I32.String) do
      @name = new_value
    end

    defw set_cookie_value(new_value: I32.String) do
      @value = new_value
    end

    defw set_domain(new_value: I32.String) do
      @domain = new_value
    end

    defw set_path(new_path: I32.String) do
      @path = new_path
    end

    defw set_secure() do
      @secure = 1
    end

    defw set_http_only() do
      @http_only = 1
    end

    defw to_string(),
         I32.String do
      build! do
        # @name <> ?= <> @value
        @name
        append!(ascii: ?=)
        @value

        if strlen(@domain) > 0 do
          # "; Domain=" <> @domain
          "; Domain="
          @domain
        end

        if strlen(@path) > 0 do
          "; Path="
          @path
        end

        if @secure do
          "; Secure"
        end

        if @http_only do
          "; HttpOnly"
        end
      end
    end
  end

  defmodule ContentSecurityPolicy do
    use Orb

    global do
      @private 0
      @public 0
      @no_store 0
      @immutable 0
      @max_age_seconds -1
      @s_max_age_seconds -1
    end
  end

  defmodule SimpleHeader do
    # TODO: Implement this algorithm: https://fetch.spec.whatwg.org/#simple-header
  end
end
