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
      Instance.call(inst, :set_max_age, 604800)
      # assert Instance.call_reading_string(inst, :to_string) == "public, max-age=604800"
      ptr = Instance.call(inst, :to_string)
      dbg(ptr)
      dbg(Instance.read_memory(inst, ptr, 10))
      dbg(Instance.read_memory(inst, 0xff, 100))
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
end
