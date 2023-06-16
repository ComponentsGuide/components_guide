defmodule ComponentsGuide.Wasm.Examples.HTTPServer.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.HTTPServer

  describe "PortfolioSite" do
    alias HTTPServer.PortfolioSite

    test "GET / returns 200" do
      inst = PortfolioSite.start()
      # put_in(inst[:method], "GET")
      Instance.call(inst, :set_method, Instance.alloc_string(inst, "GET"))
      Instance.call(inst, :set_path, Instance.alloc_string(inst, "/"))

      assert Instance.call(inst, :get_status) == 200
      # assert Instance.call_reading_string(inst, :to_string) == "foo=value"
    end

    test "GET /about returns 200" do
      inst = PortfolioSite.start()

      Instance.call(inst, :set_method, Instance.alloc_string(inst, "GET"))
      Instance.call(inst, :set_path, Instance.alloc_string(inst, "/about"))

      assert Instance.call(inst, :get_status) == 200
    end

    test "GET /foo returns 404" do
      inst = PortfolioSite.start()

      Instance.call(inst, :set_method, Instance.alloc_string(inst, "GET"))
      Instance.call(inst, :set_path, Instance.alloc_string(inst, "/foo"))

      assert Instance.call(inst, :get_status) == 404
    end
  end
end
