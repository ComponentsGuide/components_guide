defmodule ComponentsGuide.Wasm.Examples.Lemire.ParseU8 do
  @moduledoc """
  https://lemire.me/blog/2023/11/28/parsing-8-bit-integers-quickly/
  """

  use Orb

  Memory.pages(1)
  wasm_mode(U32)
  # Orb.string_type(Memory.Range)

  defw parse_uint8_naive(str: I32.String, len: I32), {I32, I32},
    i: I32,
    r: I32,
    d: I32,
    n: I32 do
    r = len &&& 0x3

    loop EachChar do
      d = str[at!: i] - ?0

      if d > 9 do
        0
        0
        return()
      end

      n = n * 10 + d
      i = i + 1
      EachChar.continue(if: i < r)
    end

    n < 256 &&& len !== 0 &&& len < 4
    n
  end

  defw parse_uint8_fastswar(str: I32.String, len: I32), {I32, I32}, digits: I32, n: I32 do
    if len === 0 or len > 3 do
      0
      0
      return()
    end

    digits =
      Memory.load!(I32, str)
      # Loads as little-endian
      |> I32.xor(0x30303030)
      |> I32.shl((4 - len) * 8)

    n =
      digits
      |> I32.mul(0x640A01)
      |> I32.rotr(24)
      |> I32.band(0x000000FF)

    # Check are valid digits
    I32.eqz((digits ||| 0x06060606 + digits) &&& 0xF0F0F0F0)
    # Check is <= 255 (after converting to big-endian)
    |> I32.band(
      I32.rotl(digits |> I32.band(0xFF00FF00), 8)
      |> I32.or(I32.rotr(digits |> I32.band(0x00FF00FF), 8)) <= 0x020505
    )

    n
  end
end
