defmodule ComponentsGuide.Wasm.Examples.Format do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator
  alias ComponentsGuide.Wasm.Examples.Memory.LinkedLists
  alias ComponentsGuide.Wasm.Examples.StringBuilder

  defmodule IntToString do
    use Wasm
    use BumpAllocator

    defmacro __using__(_) do
      quote do
        import Orb

        wasm do
          IntToString.funcp(:u32toa_count)
          IntToString.funcp(:u32toa)
          IntToString.funcp(:write_u32)
        end
      end
    end

    wasm_memory(pages: 2)

    wasm do
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

      func write_u32(value: I32, str_ptr: I32.U8.Pointer),
           I32,
           working_offset: I32.U8.Pointer,
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
    use Orb
    use BumpAllocator, export: true
    use I32.String
    use StringBuilder

    defmacro __using__(_) do
      quote do
        import Orb

        wasm do
          URLEncoding.funcp(:encode_url)
        end
      end
    end

    wasm U32 do
      func url_encode_rfc3986(str_ptr(I32.String)),
           I32.String,
           char: I32.U8,
           abc: I32,
           __dup_32: I32 do
        build_begin!()

        loop EachByte do
          char = str_ptr[at!: 0]

          if char do
            if I32.in_inclusive_range?(char, ?a, ?z)
               |> I32.or(I32.in_inclusive_range?(char, ?A, ?Z))
               |> I32.or(I32.in_inclusive_range?(char, ?0, ?9))
               |> I32.or(I32.in?(char, ~C{+:/?#[]@!$&\'()*,;=~_-.})) do
              append!(ascii: char)
            else
              append!(ascii: ?%)
              append!(hex_upper: char >>> 4)
              append!(hex_upper: char &&& 15)
              # append!(hex_upper: I32.div_u(char, 16))
              # append!(hex_upper: I32.rem_u(char, 16))

              # __dup_32 = I32.div_u(char, 16)
              # append!(hex_upper: __dup_32)
              # __dup_32 = I32.rem_u(char, 16)
              # append!(hex_upper: __dup_32)

              # append!(hex_upper: local_tee(:__dup_32, I32.div_u(char, 16)))
              # append!(hex_upper: local_tee(:__dup_32, I32.rem_u(char, 16)))
            end

            str_ptr = str_ptr + 1
            EachByte.continue()
          end
        end

        build_done!()
      end

      func url_encode_www_form(str_ptr: I32.String),
           I32.String,
           char: I32.U8,
           abc: I32,
           __dup_32: I32 do
        build_begin!()

        loop EachByte do
          char = str_ptr[at!: 0]

          if char do
            if I32.eq(char, 0x20) do
              append!(ascii: ?+)
            else
              if I32.in_inclusive_range?(char, ?a, ?z)
                 |> I32.or(I32.in_inclusive_range?(char, ?A, ?Z))
                 |> I32.or(I32.in_inclusive_range?(char, ?0, ?9))
                 |> I32.or(I32.in?(char, ~C{~_-.})) do
                append!(ascii: char)
              else
                append!(ascii: ?%)
                append!(hex_upper: char >>> 4)
                append!(hex_upper: char &&& 15)
                # append!(hex_upper: I32.div_u(char, 16))
                # append!(hex_upper: I32.rem_u(char, 16))

                # __dup_32 = I32.div_u(char, 16)
                # append!(hex_upper: __dup_32)
                # __dup_32 = I32.rem_u(char, 16)
                # append!(hex_upper: __dup_32)

                # append!(hex_upper: local_tee(:__dup_32, I32.div_u(char, 16)))
                # append!(hex_upper: local_tee(:__dup_32, I32.rem_u(char, 16)))
              end
            end

            str_ptr = str_ptr + 1
            EachByte.continue()
          end
        end

        build_done!()
      end

      func url_encode_query_www_form(list_ptr: I32.Pointer), I32.String do
        build_begin!()

        loop EachPair do
          append!(string: LinkedLists.hd!(LinkedLists.hd!(list_ptr)))
          append!(ascii: ?=)
          append!(string: LinkedLists.hd!(LinkedLists.tl!(LinkedLists.hd!(list_ptr))))

          list_ptr = LinkedLists.tl!(list_ptr)

          if list_ptr do
            append!(ascii: ?&)
          end

          EachPair.continue(if: list_ptr)
        end

        build_done!()
      end
    end

    def url_encode(str_ptr), do: call(:url_encode, str_ptr)
  end
end
