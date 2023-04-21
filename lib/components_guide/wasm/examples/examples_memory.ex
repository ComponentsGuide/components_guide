defmodule ComponentsGuide.Wasm.Examples.Memory do
  alias ComponentsGuide.Wasm

  defmodule BumpAllocator do
    use Wasm

    @page_size 64 * 1024
    @bump_start 1 * @page_size

    defwasm globals: [
              bump_offset: i32(@bump_start)
            ] do
      funcp bump_alloc(byte_size(I32)), result: I32, locals: [address: I32] do
        # TODO: check if we have allocated too much
        # and if so, either err or increase the available memory.
        address = bump_offset
        bump_offset = I32.add(bump_offset, byte_size)
        address
      end

      funcp bump_free_all() do
        bump_offset = @bump_start
      end
    end
  end
end
