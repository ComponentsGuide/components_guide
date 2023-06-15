defmodule ComponentsGuide.Wasm.Examples.Format do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

  defmodule IntToString do
    use Wasm
    require BumpAllocator

    @bump_start 1024

    # I32.global bump_offset, BumpAllocator.bump_offset()

    defwasm exported_memory: 2,
            globals: [
              bump_offset: i32(BumpAllocator.bump_offset())
            ] do
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
end
