defmodule ComponentsGuide.Wasm.Examples.HTTPServer do
  alias ComponentsGuide.Wasm.Examples.Memory
  alias ComponentsGuide.Wasm.Examples.StringBuilder
  alias ComponentsGuide.Wasm.Examples.Format.IntToString

  defmodule PortfolioSite do
    use Orb
    use Memory.BumpAllocator
    use I32.String
    use IntToString
    use StringBuilder

    global(
      method: I32.String.null(),
      path: I32.String.null()
    )

    wasm do
      func(alloc(byte_count(I32)), I32, do: call(:bump_alloc, byte_count))

      I32.prop(:method, as: :set_method)
      I32.prop(:path, as: :set_path)

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
