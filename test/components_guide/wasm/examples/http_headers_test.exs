defmodule ComponentsGuide.Wasm.Examples.HTTPHeaders.Test do
  use ExUnit.Case, async: true

  # alias ComponentsGuide.Wasm.Instance
  alias OrbWasmtime.Instance
  alias ComponentsGuide.Wasm.Examples.HTTPHeaders
  import ComponentsGuide.Wasm, only: [to_wasm: 1]

  describe "CacheControl" do
    alias HTTPHeaders.CacheControl

    test "default" do
      inst = Instance.run(CacheControl)

      assert to_string(inst) == "max-age=0"
    end

    test "public" do
      inst = Instance.run(CacheControl)
      Instance.call(inst, :set_public)
      # assert Instance.call_reading_string(inst, :to_string) == "public"
      assert to_string(inst) == "public"
    end

    test "public, max-age=604800" do
      inst = Instance.run(CacheControl)
      Instance.call(inst, :set_public)
      Instance.call(inst, :set_max_age, 604_800)
      assert Instance.call_reading_string(inst, :to_string) == "public, max-age=604800"
    end

    test "public, max-age=604800, immutable" do
      inst = Instance.run(CacheControl)
      Instance.call(inst, :set_public)
      Instance.call(inst, :set_immutable)
      Instance.call(inst, :set_max_age, 604_800)
      assert Instance.call_reading_string(inst, :to_string) == "public, max-age=604800, immutable"
    end

    test "public, max-age=7200, s-maxage=3600" do
      inst = Instance.run(CacheControl)
      Instance.call(inst, :set_public)
      Instance.call(inst, :set_max_age, 7_200)
      Instance.call(inst, :set_shared_max_age, 3_600)

      assert Instance.call_reading_string(inst, :to_string) ==
               "public, max-age=7200, s-maxage=3600"
    end

    test "private" do
      inst = Instance.run(CacheControl)
      Instance.call(inst, :set_private)
      assert Instance.call_reading_string(inst, :to_string) == "private"
    end

    test "private, max-age=604800" do
      inst = Instance.run(CacheControl)
      Instance.call(inst, :set_private)
      Instance.call(inst, :set_max_age, 604_800)
      assert Instance.call_reading_string(inst, :to_string) == "private, max-age=604800"
    end

    test "no-store" do
      inst = Instance.run(CacheControl)
      Instance.call(inst, :set_no_store)
      assert Instance.call_reading_string(inst, :to_string) == "no-store"
    end

    test "immutable" do
      inst = Instance.run(CacheControl)
      Instance.call(inst, :set_immutable)
      assert Instance.call_reading_string(inst, :to_string) == "immutable"
    end
  end

  describe "SetCookie" do
    alias HTTPHeaders.SetCookie

    test "wasm size" do
      assert byte_size(to_wasm(SetCookie)) == 892
    end

    test "name and value" do
      inst = Instance.run(SetCookie)
      # put_in(inst[:name], "foo")
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      # Instance.call(inst, :"name=", Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))

      # inst[{String, :to_string}]
      assert Instance.call_reading_string(inst, :to_string) == "foo=value"
    end

    test "domain" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_domain, Instance.alloc_string(inst, "foo.example.com"))
      assert Instance.call_reading_string(inst, :to_string) == "foo=value; Domain=foo.example.com"
    end

    test "HttpOnly" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_http_only)
      assert Instance.call_reading_string(inst, :to_string) == "foo=value; HttpOnly"
    end

    test "HttpOnly Secure" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_http_only)
      Instance.call(inst, :set_secure)
      assert Instance.call_reading_string(inst, :to_string) == "foo=value; Secure; HttpOnly"
    end

    test "Domain HttpOnly Secure" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_domain, Instance.alloc_string(inst, "foo.example.com"))
      Instance.call(inst, :set_http_only)
      Instance.call(inst, :set_secure)

      assert Instance.call_reading_string(inst, :to_string) ==
               "foo=value; Domain=foo.example.com; Secure; HttpOnly"
    end

    test "Domain Path HttpOnly Secure" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_domain, Instance.alloc_string(inst, "foo.example.com"))
      Instance.call(inst, :set_path, Instance.alloc_string(inst, "/"))
      Instance.call(inst, :set_http_only)
      Instance.call(inst, :set_secure)

      assert Instance.call_reading_string(inst, :to_string) ==
               "foo=value; Domain=foo.example.com; Path=/; Secure; HttpOnly"
    end
  end
end
