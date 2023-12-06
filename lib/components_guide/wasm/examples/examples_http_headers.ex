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
            ~S|public|
          else
            if @private do
              ~S|private|
            else
              if @no_store do
                ~S|no-store|
              end
            end
          end

          if @max_age_seconds > 0 do
            if appended?(), do: ~S|, |

            ~S|max-age=|
            append!(decimal_u32: @max_age_seconds)
          end

          if @s_max_age_seconds > 0 do
            if appended?(), do: ~S|, |

            ~S|s-maxage=|
            append!(decimal_u32: @s_max_age_seconds)
          end

          if @immutable do
            if appended?(), do: ~S|, |

            ~S|immutable|
          end

          if not appended?() do
            ~S|max-age=0|
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
        append!(string: @name)
        append!(ascii: ?=)
        append!(string: @value)

        if strlen(@domain) > 0 do
          # "; Domain=" <> @domain
          "; Domain="
          append!(string: @domain)
        end

        if strlen(@path) > 0 do
          "; Path="
          append!(string: @path)
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
