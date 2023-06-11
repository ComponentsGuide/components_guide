defmodule ComponentsGuide.Wasm.Examples.SVGTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.SVG

  describe "Square" do
    alias SVG.Square

    test "creates a black square" do
      instance = Square.start()

      svg = Square.read_body(instance)

      assert svg == ~S"""
             <svg width="64" height="64"><rect width="64" height="64" fill="#000000ff" /></svg>
             """
    end

    test "can set color_hex global" do
      instance = Square.start()

      Instance.set_global(instance, :color_hex, 0xAA33BBFF)
      svg = Square.read_body(instance)

      assert svg == ~S"""
             <svg width="64" height="64"><rect width="64" height="64" fill="#aa33bbff" /></svg>
             """
    end
  end
end
