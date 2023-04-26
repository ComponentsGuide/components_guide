defmodule ComponentsGuide.Wasm.Examples.ParserTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.SVG

  describe "Square" do
    alias SVG.Square

    test "works" do
      instance = Square.start()

      svg = Instance.call_joining_string_chunks(instance, :next_body_chunk)

      assert svg == ~S"""
             <svg width="64" height="64"><rect width="64" height="64" fill="00000000" /></svg>
             """
    end
  end
end
