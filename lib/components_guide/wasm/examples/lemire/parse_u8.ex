defmodule ComponentsGuide.Wasm.Examples.Lemire.ParseU8 do
  @moduledoc """
  https://lemire.me/blog/2023/11/28/parsing-8-bit-integers-quickly/
  """

  use Orb

  Memory.pages(1)

  wasm_mode(U32)

  defw parse_uint8_naive(str: I32.String, len: I32), {I32, I32},
    i: I32,
    r: I32,
    d: I32,
    n: I32,
    y: I32 do
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

  defw parse_uint8_fastswar(str: I32.String, len: I32), {I32, I32}, digits: I32, y: I32 do
    # <<< 8
    digits = Memory.load!(I32, str)
    # memcpy(&digits.as_int, str, sizeof(digits));
    digits = I32.xor(digits, 0x30303030)
    # digits.as_int <<= (4 - (len & 0x3)) * 8;
    digits = I32.shl(digits, (4 - (len &&& 0x3)) * 8)
    y = (0x640A0100 * digits) >>> 32 &&& 0xFF
    # *num = (uint8_t)(y);
    (digits &&& 0xF0F0F0F0) === 0 &&& y < 256 &&& len !== 0 &&& len < 4
    # digits &&& 0xF0F0F0F0
    y
  end
end
