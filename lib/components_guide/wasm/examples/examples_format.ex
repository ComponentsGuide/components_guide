defmodule ComponentsGuide.Wasm.Examples.Format do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.WasmBuilder
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

  defmodule IntToString do
    use Wasm
    use BumpAllocator

    defmacro __using__(_) do
      quote do
        import WasmBuilder

        wasm do
          IntToString.funcp(:u32toa_count)
          IntToString.funcp(:u32toa)
        end
      end
    end

    defwasm exported_memory: 2 do
      func u32toa_count(value(I32)),
           I32,
           digit_count: I32,
           digit: I32 do
        loop Digits do
          digit_count = I32.add(digit_count, 1)

          digit = I32.rem_u(value, 10)
          value = I32.div_u(value, 10)

          Digits.continue(if: I32.gt_u(value, 0))
        end

        digit_count
      end

      func write_u32(value(I32), str_ptr(I32)),
           I32,
           working_offset: I32,
           last_offset: I32,
           digit: I32 do
        last_offset = I32.add(str_ptr, call(:u32toa_count, value))
        # We then start from the back, as we have to print the digits in reverse.
        working_offset = last_offset

        loop Digits do
          working_offset = I32.sub(working_offset, 1)

          digit = I32.rem_u(value, 10)
          value = I32.div_u(value, 10)
          memory32_8![working_offset] = I32.add(?0, digit)

          Digits.continue(if: I32.gt_u(value, 0))
        end

        last_offset
      end

      func u32toa(value(I32), end_offset(I32)),
           I32,
           working_offset: I32,
           digit: I32 do
        # Max int is 4294967296 which has 10 digits. We add one for nul byte.
        # We “allocate” all 11 bytes upfront to make the algorithm easier.
        # bump_offset = I32.add(bump_offset, 11)
        # We then start from the back, as we have to print the digits in reverse.
        working_offset = end_offset

        loop Digits do
          working_offset = I32.sub(working_offset, 1)

          digit = I32.rem_u(value, 10)
          value = I32.div_u(value, 10)
          memory32_8![working_offset] = I32.add(?0, digit)

          Digits.continue(if: I32.gt_u(value, 0))
        end

        working_offset
      end
    end

    def u32toa_count(value), do: call(:u32toa_count, value)
    def u32toa(value, end_offset), do: call(:u32toa, value, end_offset)
    def write_u32(value, str_ptr), do: call(:write_u32, value, str_ptr)
  end

  defmodule URLEncoding do
    use WasmBuilder
    use BumpAllocator, export: true

    defmacro __using__(_) do
      quote do
        import WasmBuilder

        wasm do
          URLEncoding.funcp(:encode_url)
        end
      end
    end

    wasm do
      func url_encode(str_ptr(I32.String)),
           I32.String,
           char: I32,
           abc: I32,
           __dup_32: I32 do
        write_start!()

        loop EachByte do
          char = memory32_8![str_ptr].unsigned

          if char do
            if I32.in_inclusive_range?(char, ?a, ?z)
               |> I32.or(I32.in_inclusive_range?(char, ?A, ?Z))
               |> I32.or(I32.in_inclusive_range?(char, ?0, ?9))
               |> I32.or(I32.in?(char, ~C{:/?#[]@!$&\'()*+,;=~_-.})) do
              bump_write!(ascii: char)
            else
              # bump_write!([])

              # bump_write!(
              #   ascii: ?%,
              #   hex_upper: I32.div_u(char, 16),
              # )
              # bump_write!(
              #   ascii: ?%,
              #   hex_upper: I32.div_u(char, 16),
              #   hex_upper: I32.rem_u(char, 16)
              # )

              bump_write!(ascii: ?%)
              bump_write!(hex_upper: I32.u!(char >>> 4))
              bump_write!(hex_upper: I32.u!(char &&& 15))
              # bump_write!(hex_upper: I32.div_u(char, 16))
              # bump_write!(hex_upper: I32.rem_u(char, 16))

              # __dup_32 = I32.div_u(char, 16)
              # bump_write!(hex_upper: __dup_32)
              # __dup_32 = I32.rem_u(char, 16)
              # bump_write!(hex_upper: __dup_32)

              # bump_write!(hex_upper: local_tee(:__dup_32, I32.div_u(char, 16)))
              # bump_write!(hex_upper: local_tee(:__dup_32, I32.rem_u(char, 16)))
            end

            str_ptr = I32.add(str_ptr, 1)
            # i = I32.add(i, 1)
            # i = I32.u!(i + 1)
            # I32.increment!(i)
            EachByte.continue()
          end
        end

        write_done!()
      end
    end

    def url_encode(str_ptr), do: call(:url_encode, str_ptr)
  end
end
