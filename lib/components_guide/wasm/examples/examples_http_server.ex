defmodule ComponentsGuide.Wasm.Examples.HTTPServer do
  alias ComponentsGuide.Wasm.Examples.StringBuilder
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  defmodule PortfolioSite do
    use Orb
    use SilverOrb.BumpAllocator
    use I32.String
    use IntToString
    use StringBuilder

    SilverOrb.BumpAllocator.export_alloc()

    I32.global(
      method: 0,
      path: 0
    )

    defw set_method(method: I32.UnsafePointer) do
      @method = method
    end

    defw set_path(path: I32.UnsafePointer) do
      @path = path
    end

    defw get_status(), I32 do
      I32.String.match @method do
        ~S"GET" ->
          I32.String.match @path do
            ~S"/" ->
              200

            ~S"/about" ->
              200

            _ ->
              404
          end

        _ ->
          405
      end
    end

    defw get_body(), I32.String do
      if not I32.String.streq(@method, ~S"GET") do
        return(~S"""
        <!doctype html>
        <h1>Method not allowed</h1>
        """)
      end

      I32.String.match @path do
        ~S"/" ->
          ~S"""
          <!doctype html>
          <h1>Welcome</h1>
          """

        ~S"/about" ->
          ~S"""
          <!doctype html>
          <h1>About</h1>
          """

        _ ->
          build! do
            ~S"""
            <!doctype html>
            """

            ~S"<h1>Not found: "
            append!(string: @path)
            ~S"</h1>\n"
          end

          # ~E"""
          # <!doctype html>
          # <h1>Not found: <%= path %></h1>
          # """
      end
    end
  end
end
