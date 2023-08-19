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

    wasm do
      I32.attr_writer(:method, as: :set_method)
      I32.attr_writer(:path, as: :set_path)

      func get_status(), I32 do
        if I32.String.streq(@method, ~S"GET") |> I32.eqz() do
          return(405)
        end

        I32.String.match @path do
          ~S"/" ->
            200

          ~S"/about" ->
            200

          _ ->
            404
        end
      end

      func get_body(), I32.String do
        if I32.String.streq(@method, ~S"GET") |> I32.eqz() do
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
            join!([
              ~S"""
              <!doctype html>
              """,
              ~S"<h1>Not found: ",
              @path,
              ~S"</h1>\n"
            ])

            # ~E"""
            # <!doctype html>
            # <h1>Not found: <%= path %></h1>
            # """
        end
      end
    end
  end
end
