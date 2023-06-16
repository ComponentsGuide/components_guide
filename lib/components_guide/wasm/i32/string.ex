defmodule ComponentsGuide.WasmBuilder.I32.String do
  use ComponentsGuide.WasmBuilder

  @wasm_memory 1

  defwasm do
    func streq(address_a(I32), address_b(I32)),
      result: I32,
      locals: [i: I32, byte_a: I32, byte_b: I32] do
      loop EachByte, result: I32 do
        byte_a = memory32_8![I32.add(address_a, i)].unsigned
        byte_b = memory32_8![I32.add(address_b, i)].unsigned

        if I32.eqz(byte_a) do
          return(I32.eqz(byte_b))
        end

        if I32.eq(byte_a, byte_b) do
          i = I32.add(i, 1)
          EachByte.continue()
        end

        return(0x0)
      end
    end
  end

  def streq(address_a, address_b) do
    call(:streq, address_a, address_b)
  end
end
