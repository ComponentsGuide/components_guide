defmodule ComponentsGuide.Wasm.Examples.ParserTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Parser

  describe "HexConversion" do
    alias Parser.HexConversion

    test "i32_to_hex_lower" do
      inst = HexConversion.start()
      i32_to_hex_lower = Instance.capture(inst, :i32_to_hex_lower, 2)
      read = &Instance.read_memory(inst, &1, 8)

      i32_to_hex_lower.(0x00000000, 0x100)
      assert read.(0x100) == "00000000"

      i32_to_hex_lower.(0x00ABCDEF, 0x100)
      assert read.(0x100) == "00abcdef"

      i32_to_hex_lower.(0x44ABCDEF, 0x100)
      assert read.(0x100) == "44abcdef"

      i32_to_hex_lower.(0xFFFF_FFFF, 0x100)
      assert read.(0x100) == "ffffffff"

      i32_to_hex_lower.(1, 0x100)
      assert read.(0x100) == "00000001"

      # Does NOT write outside its bounds.
      assert Instance.read_memory(inst, 0x100 - 1, 1) == <<0>>
      assert Instance.read_memory(inst, 0x100 + 9, 1) == <<0>>
    end
  end

  describe "DomainNames" do
    alias Parser.DomainNames

    test "lookup_domain_name" do
      inst = DomainNames.start()
      lookup_domain_name = Instance.capture(inst, :lookup_domain_name, 1)
      alloc_string = &Instance.alloc_string(inst, &1)

      assert lookup_domain_name.(alloc_string.("com")) == 0
      assert lookup_domain_name.(alloc_string.("org")) == 0
      assert lookup_domain_name.(alloc_string.("foo")) == 0
    end
  end
end
