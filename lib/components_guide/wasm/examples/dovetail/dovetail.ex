defmodule ComponentsGuide.Wasm.Examples.Dovetail do
  # https://github.com/RoyalIcing/Dovetail

  alias ComponentsGuide.Wasm.Examples.Dovetail.ElementsStack
  use Orb
  alias require SilverOrb.Arena

  Arena.def(ElementsStack, pages: 1)
  Arena.def(Document, pages: 1)

  defw text(string: I32.String), I32.UnsafePointer, size: I32 do
    size = Orb.String.byte_size(string)
    ElementsStack.alloc!(size)
    # TODO
  end

  defw link(href_ptr: I32.String, text_ptr: I32.UnsafePointer) do
    # TODO
  end

  defw h(level: I32, text_ptr: I32.UnsafePointer) do
    # TODO
  end

  defw p(text_ptr: I32.UnsafePointer) do
    # TODO
  end

  defw nav(name: I32.String, items_ptr: I32.UnsafePointer) do
    # TODO
  end

  # An Elixir list of items, which is added to the stack.
  def items(items) do

  end

  defw button(text_ptr: I32.UnsafePointer) do
    # TODO
  end

  defw textbox(text_ptr: I32.UnsafePointer) do
    # TODO
  end

  defw form_get(path_ptr: I32.String, text_ptr: I32.UnsafePointer) do
    # TODO
  end

  defw form_post(path_ptr: I32.String, text_ptr: I32.UnsafePointer) do
    # TODO
  end
end
