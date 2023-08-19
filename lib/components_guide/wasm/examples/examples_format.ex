defmodule ComponentsGuide.Wasm.Examples.Format do
  defmodule IntToString do
    use Orb
    use SilverOrb.BumpAllocator

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

    Memory.pages(2)

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

      func write_u32(value: I32, str_ptr: I32.U8.UnsafePointer),
           I32,
           working_offset: I32.U8.UnsafePointer,
           last_offset: I32,
           digit: I32 do
        last_offset = I32.add(str_ptr, call(:u32toa_count, value))
        # We then start from the back, as we have to print the digits in reverse.
        working_offset = last_offset

        loop Digits do
          working_offset = I32.sub(working_offset, 1)

          digit = I32.rem_u(value, 10)
          value = I32.div_u(value, 10)
          Memory.store!(I32.U8, working_offset, I32.add(?0, digit))
          # memory32_8![working_offset] = I32.add(?0, digit)

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

    def u32toa_count(value), do: Orb.DSL.call(:u32toa_count, value)
    def u32toa(value, end_offset), do: Orb.DSL.call(:u32toa, value, end_offset)
    def write_u32(value, str_ptr), do: Orb.DSL.call(:write_u32, value, str_ptr)
  end

  defmodule FloatToString do
    use Orb
    use SilverOrb.BumpAllocator

    defmacro __using__(_) do
      quote do
        import Orb

        wasm do
          IntToString.funcp(:format_f32)
        end
      end
    end

    Memory.pages(2)

    wasm F32 do
      func format_f32(value: F32, str_ptr: I32.U8.UnsafePointer, precision: I32),
           digit: I32 do


          # TODO: handle -0
          if value < 0 do
            # Memory.store!(I32.U8, str_ptr, ?-)
            {:i32, :store8, str_ptr, ?-}
            str_ptr = I32.add(str_ptr, 1)
            value = -1 * value;
          end

          # TODO: handle NaN
          # if (math.isNan(x)) {
            #     return writer.writeAll("nan");
            # }
          # TODO: handle Infinity
          # if (math.isPositiveInf(x)) {
          #     return writer.writeAll("inf");
          # }
          if value === 0.0 do
            {:i32, :store8, str_ptr, ?0}
            str_ptr = I32.add(str_ptr, 1)

            # if (options.precision) |precision| {
            #     if (precision != 0) {
            #         try writer.writeAll(".");
            #         var i: usize = 0;
            #         while (i < precision) : (i += 1) {
            #             try writer.writeAll("0");
            #         }
            #     }
            # }

            return()
          end

          # non-special case, use errol3

          # var buffer: [32]u8 = undefined;
          # var float_decimal = errol.errol3(x, buffer[0..]);

          # if (options.precision) |precision| {
          #     errol.roundToPrecision(&float_decimal, precision, errol.RoundMode.Decimal);

          #     // exp < 0 means the leading is always 0 as errol result is normalized.

          #     var num_digits_whole = if (float_decimal.exp > 0) @intCast(usize, float_decimal.exp) else 0;

          #     // the actual slice into the buffer, we may need to zero-pad between num_digits_whole and this.

          #     var num_digits_whole_no_pad = math.min(num_digits_whole, float_decimal.digits.len);

          #     if (num_digits_whole > 0) {
          #         // We may have to zero pad, for instance 1e4 requires zero padding.

          #         try writer.writeAll(float_decimal.digits[0..num_digits_whole_no_pad]);

          #         var i = num_digits_whole_no_pad;
          #         while (i < num_digits_whole) : (i += 1) {
          #             try writer.writeAll("0");
          #         }
          #     } else {
          #         try writer.writeAll("0");
          #     }

          #     // {.0} special case doesn't want a trailing '.'

          #     if (precision == 0) {
          #         return;
          #     }

          #     try writer.writeAll(".");

          #     // Keep track of fractional count printed for case where we pre-pad then post-pad with 0's.

          #     var printed: usize = 0;

          #     // Zero-fill until we reach significant digits or run out of precision.

          #     if (float_decimal.exp <= 0) {
          #         const zero_digit_count = @intCast(usize, -float_decimal.exp);
          #         const zeros_to_print = math.min(zero_digit_count, precision);

          #         var i: usize = 0;
          #         while (i < zeros_to_print) : (i += 1) {
          #             try writer.writeAll("0");
          #             printed += 1;
          #         }

          #         if (printed >= precision) {
          #             return;
          #         }
          #     }

          #     // Remaining fractional portion, zero-padding if insufficient.

          #     assert(precision >= printed);
          #     if (num_digits_whole_no_pad + precision - printed < float_decimal.digits.len) {
          #         try writer.writeAll(float_decimal.digits[num_digits_whole_no_pad .. num_digits_whole_no_pad + precision - printed]);
          #         return;
          #     } else {
          #         try writer.writeAll(float_decimal.digits[num_digits_whole_no_pad..]);
          #         printed += float_decimal.digits.len - num_digits_whole_no_pad;

          #         while (printed < precision) : (printed += 1) {
          #             try writer.writeAll("0");
          #         }
          #     }
          # } else {

              # // exp < 0 means the leading is always 0 as errol result is normalized.

              # var num_digits_whole = if (float_decimal.exp > 0) @intCast(usize, float_decimal.exp) else 0;

              # // the actual slice into the buffer, we may need to zero-pad between num_digits_whole and this.

              # var num_digits_whole_no_pad = math.min(num_digits_whole, float_decimal.digits.len);

              # if (num_digits_whole > 0) {
              #     // We may have to zero pad, for instance 1e4 requires zero padding.

              #     try writer.writeAll(float_decimal.digits[0..num_digits_whole_no_pad]);

              #     var i = num_digits_whole_no_pad;
              #     while (i < num_digits_whole) : (i += 1) {
              #         try writer.writeAll("0");
              #     }
              # } else {
              #     try writer.writeAll("0");
              # }

              # // Omit `.` if no fractional portion

              # if (float_decimal.exp >= 0 and num_digits_whole_no_pad == float_decimal.digits.len) {
              #     return;
              # }

              # try writer.writeAll(".");

              # // Zero-fill until we reach significant digits or run out of precision.

              # if (float_decimal.exp < 0) {
              #     const zero_digit_count = @intCast(usize, -float_decimal.exp);

              #     var i: usize = 0;
              #     while (i < zero_digit_count) : (i += 1) {
              #         try writer.writeAll("0");
              #     }
              # }

              # try writer.writeAll(float_decimal.digits[num_digits_whole_no_pad..]);
          # }
      end
    end

    def u32toa_count(value), do: Orb.DSL.call(:u32toa_count, value)
    def u32toa(value, end_offset), do: Orb.DSL.call(:u32toa, value, end_offset)
    def write_u32(value, str_ptr), do: Orb.DSL.call(:write_u32, value, str_ptr)
  end
end
