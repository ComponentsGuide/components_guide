defmodule ComponentsGuide.Wasm.Examples.HTTPServer do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Writer
  alias ComponentsGuide.Wasm.Examples.Memory.MemEql
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.StringHelpers
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  defmodule PortfolioSite do
    use Wasm
    use BumpAllocator
    import StringHelpers
    import Writer

    # @wasm_string_func :get_body

    def start() do
      try do
        Wasm.Instance.run(__MODULE__)
      rescue
        x in [RuntimeError] ->
          # IO.puts(__MODULE__.to_wat())
          Logger.error(__MODULE__.to_wat())
          reraise x, __STACKTRACE__
      end
    end

    # @global bump_offset: i32(BumpAllocator.bump_offset()),
    #         method: i32_null_string(),
    #         path: i32_null_string()

    defwasm globals: [
              bump_offset: i32(BumpAllocator.bump_offset()),
              method: i32_null_string(),
              path: i32_null_string()
            ] do
      BumpAllocator.funcp(:bump_alloc)
      BumpAllocator.funcp(:bump_memcpy)
      StringHelpers.funcp(:strlen)
      IntToString.funcp(:u32toa_count)
      IntToString.funcp(:u32toa)
      MemEql.funcp(:mem_eql_8)

      func(alloc(byte_count(I32)), I32, do: call(:bump_alloc, byte_count))

      I32.attr_writer(:method, as: :set_method)
      I32.attr_writer(:path, as: :set_path)

      func get_status(), I32 do
        I32.cond do
          MemEql.mem_eql_8(path, const("/")) ->
            200

          MemEql.mem_eql_8(path, const("/about")) ->
            200

          true ->
            404
        end

        # I32.String.match path do
        #   const("/") ->
        #     200
        #
        #   const("/about") ->
        #     200
        #
        #   _ ->
        #     404
        # end
      end

      func get_body(), I32.String, start: I32.String, writer: I32.String do
        I32.cond do
          MemEql.mem_eql_8(path, ~S"/") ->
            ~S"""
            <!doctype html>
            <h1>Welcome</h1>
            """

          MemEql.mem_eql_8(path, ~S"/about") ->
            ~S"""
            <!doctype html>
            <h1>About</h1>
            """

          true ->
            write!([
              ~S"""
              <!doctype html>
              """,
              ~S"<h1>Not found: ",
              path,
              ~S"</h1>\n"
            ])

            # ~s"""
            # <!doctype html>
            # <h1>Not found: <%= path %></h1>
            # """
        end
      end

      #       func to_string(),
      #            I32.String,
      #            str: I32,
      #            byte_count: I32,
      #            writer: I32,
      #            name_len: I32,
      #            value_len: I32,
      #            domain_len: I32,
      #            path_len: I32,
      #            extra_len: I32 do
      #         name_len = strlen(name)
      #         value_len = strlen(value)
      #         domain_len = strlen(domain)
      #         path_len = strlen(path)
      #
      #         extra_len =
      #           I32.add([
      #             I32.when?(domain_len, do: I32.add(domain_len, byte_size("; Domain=")), else: 0),
      #             I32.when?(path_len, do: I32.add(path_len, byte_size("; Path=")), else: 0),
      #             I32.when?(secure, do: byte_size("; Secure"), else: 0),
      #             I32.when?(http_only, do: byte_size("; HttpOnly"), else: 0)
      #           ])
      #
      #         byte_count = I32.add([name_len, 1, value_len, extra_len])
      #
      #         # Add 1 for nul-terminator
      #         str = alloc(I32.add(byte_count, 1))
      #         writer = str
      #
      #         write!(name, name_len)
      #         write!(ascii: ?=)
      #         write!(value, value_len)
      #
      #         if domain_len do
      #           write!(const("; Domain="))
      #           write!(domain, domain_len)
      #         end
      #
      #         if path_len do
      #           write!(const("; Path="))
      #           write!(path, path_len)
      #         end
      #
      #         if secure do
      #           write!(const("; Secure"))
      #         end
      #
      #         if http_only do
      #           write!(const("; HttpOnly"))
      #         end
      #
      #         assert!(I32.eq(writer, I32.add(str, byte_count)))
      #
      #         str
      #       end
    end
  end
end
