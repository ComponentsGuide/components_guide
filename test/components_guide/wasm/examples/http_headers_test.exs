defmodule ComponentsGuide.Wasm.Examples.HTTPHeaders.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.HTTPHeaders

  describe "CacheControl" do
    alias HTTPHeaders.CacheControl

    test "default" do
      inst = CacheControl.start()

      assert Instance.call_reading_string(inst, :to_string) == "hello"
    end

    test "public" do
      inst = CacheControl.start()
      Instance.call(inst, :set_public)
      assert Instance.call_reading_string(inst, :to_string) == "public"
    end

    test "public, max-age=604800" do
      inst = CacheControl.start()
      Instance.call(inst, :set_public)
      Instance.call(inst, :set_max_age, 604_800)
      assert Instance.call_reading_string(inst, :to_string) == "public, max-age=604800"
    end

    test "public, max-age=604800, immutable" do
      inst = CacheControl.start()
      Instance.call(inst, :set_public)
      Instance.call(inst, :set_immutable)
      Instance.call(inst, :set_max_age, 604_800)
      assert Instance.call_reading_string(inst, :to_string) == "public, max-age=604800, immutable"
    end

    test "private" do
      inst = CacheControl.start()
      Instance.call(inst, :set_private)
      assert Instance.call_reading_string(inst, :to_string) == "private"
    end

    test "immutable" do
      inst = CacheControl.start()
      Instance.call(inst, :set_immutable)
      assert Instance.call_reading_string(inst, :to_string) == "immutable"
    end
  end

  describe "SetCookie" do
    alias HTTPHeaders.SetCookie

    test "name and value" do
      inst = SetCookie.start()
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      assert Instance.call_reading_string(inst, :to_string) == "foo=value"
    end

    test "HttpOnly" do
      inst = SetCookie.start()
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_http_only)
      assert Instance.call_reading_string(inst, :to_string) == "foo=value; HttpOnly"
    end

    test "HttpOnly Secure" do
      inst = SetCookie.start()
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_http_only)
      Instance.call(inst, :set_secure)
      assert Instance.call_reading_string(inst, :to_string) == "foo=value; Secure; HttpOnly"
    end
  end
end
