defmodule ComponentsGuide.Wasm.Examples.Cors do
  defmodule Browser do
    use Orb

    global :export_mutable do
      @origin "example.com"
      @method "GET"
      # @path "/"
      @origin_headers ""
    end

    defw can_access_origin?(), I32 do
      # 1. request origin to get headers
      # 2. process headers to calculate 0 or 1
      0
    end
  end

  defmodule OriginA do
    use Orb

    Memory.pages(1)

    global :export_mutable do
      @method "GET"
    end

    defw http_headers do
      [
        "Access-Control-Allow-Origin: a.com",
        "Access-Control-Allow-Methods: GET, POST"
      ]
      |> Enum.join("\r\n")
    end
  end

  defmodule OriginB do
    use Orb

    Memory.pages(1)

    global :export_mutable do
      @method "GET"
    end

    defw http_headers do
      [
        "Access-Control-Allow-Origin: b.com",
        "Access-Control-Allow-Methods: GET, POST"
      ]
      |> Enum.join("\r\n")
    end
  end
end
