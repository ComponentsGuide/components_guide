defmodule ComponentsGuide.Wasm.Examples.Format.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Format

  describe "IntToString" do
    alias Format.IntToString

    test "u32toa_count" do
      assert Wasm.call(IntToString, :u32toa_count, 0) == 1
      assert Wasm.call(IntToString, :u32toa_count, 7) == 1
      assert Wasm.call(IntToString, :u32toa_count, 17) == 2
      assert Wasm.call(IntToString, :u32toa_count, 173) == 3
      assert Wasm.call(IntToString, :u32toa_count, 604_800) == 6
    end
  end
  
  describe "URLEncoding" do
    alias Format.URLEncoding

    test "url_encode" do
      inst = Instance.run(URLEncoding)
      url_encode = Instance.capture(inst, String, :url_encode, 1)
      
      assert url_encode.("123") == "123"
      assert url_encode.("two words") == "two%20words"
    end
  end
end
