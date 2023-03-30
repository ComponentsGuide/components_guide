defmodule ComponentsGuide.Wasm.WasmExamples do
  # alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Rustler.WasmBuilder

  defmodule EscapeHTML do
    use WasmBuilder

    defwasm imports: [env: [buffer: memory(2)]] do
      func escape_html, result: I32, locals: [read_offset: I32, write_offset: I32, char: I32] do
        read_offset = 1024
        write_offset = 1024 + 1024

        defloop EachChar, result: I32 do
          defblock Outer do
            char = memory32_8![read_offset].unsigned

            if I32.eq(char, ?&) do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?a
              memory32_8![I32.add(write_offset, 2)] = ?m
              memory32_8![I32.add(write_offset, 3)] = ?p
              memory32_8![I32.add(write_offset, 4)] = ?;
              write_offset = I32.add(write_offset, 4)
              br(Outer)
            end

            if I32.eq(char, ?<) do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?l
              memory32_8![I32.add(write_offset, 2)] = ?t
              memory32_8![I32.add(write_offset, 3)] = ?;
              write_offset = I32.add(write_offset, 3)
              br(Outer)
            end

            if I32.eq(char, ?>) do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?g
              memory32_8![I32.add(write_offset, 2)] = ?t
              memory32_8![I32.add(write_offset, 3)] = ?;
              write_offset = I32.add(write_offset, 3)
              br(Outer)
            end

            if I32.eq(char, ?") do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?q
              memory32_8![I32.add(write_offset, 2)] = ?u
              memory32_8![I32.add(write_offset, 3)] = ?o
              memory32_8![I32.add(write_offset, 4)] = ?t
              memory32_8![I32.add(write_offset, 5)] = ?;
              write_offset = I32.add(write_offset, 5)
              br(Outer)
            end

            if I32.eq(char, ?') do
              memory32_8![write_offset] = ?&
              memory32_8![I32.add(write_offset, 1)] = ?#
              memory32_8![I32.add(write_offset, 2)] = ?3
              memory32_8![I32.add(write_offset, 3)] = ?9
              memory32_8![I32.add(write_offset, 4)] = ?;
              write_offset = I32.add(write_offset, 4)
              br(Outer)
            end

            memory32_8![write_offset] = char
            br(Outer, if: char)

            # br(Outer, if: char)
            # Outer.branch(if: char)
            # Outer.if(char)
            push(I32.sub(write_offset, 1024 + 1024))
            return()
          end

          read_offset = I32.add(read_offset, 1)
          write_offset = I32.add(write_offset, 1)
          br(EachChar)
        end
      end
    end
  end

  defmodule HTMLPage do
    use WasmBuilder

    defwasm imports: [
              env: [buffer: memory(2)]
            ],
            globals: [
              count: i32(0)
            ] do
      # data_nil_terminated(4, hello2())
      data_nil_terminated(4, "<!doctype html>")
      data_nil_terminated(20, "<h1>Good</h1>")
      data_nil_terminated(40, "<h1>Bad</h1>")
      data_nil_terminated(60, "content-type: text/html;charset=utf-8")

      # defdata doctype, do: "<!doctype html>"
      # defdata good_heading, do: "<h1>Good</h1>"
      # defdata bad_heading, do: "<h1>Bad</h1>"

      # data_nil_terminated(4, :html,
      #   doctype: "<!doctype html>",
      #   good_heading: "<h1>Good</h1>",
      #   bad_heading: "<h1>Bad</h1>",
      # )

      func get_request_body_write_offset, result: I32 do
        65536
      end

      func start do
        count = 0
      end

      funcp get_is_valid, result: I32 do
        I32.eq(I32.load8_u(65536), ?g)
      end

      func get_status, result: I32, locals: [is_valid: I32] do
        is_valid = call(:get_is_valid)
        I32.if_else(is_valid, do: 200, else: 400)
      end

      func get_headers, result: I32 do
        60
      end

      func body, result: I32, locals: [is_valid: I32] do
        is_valid = call(:get_is_valid)
        count = I32.add(count, 1)

        # I32.if_else(I32.eq(count, 1),
        #   do: 4,
        #   else: I32.if_else(is_valid, do: 20, else: 40)
        # )
        # I32.if_else(I32.eq(count, 1),
        #   do: lookup_data(:doctype),
        #   else: I32.if_else(is_valid, do: lookup_data(:good_heading), else: lookup_data(:bad_heading))
        # )
        I32.if_else(I32.eq(count, 1),
          do: 4,
          else: I32.if_else(I32.eq(count, 2), do: I32.if_else(is_valid, do: 20, else: 40), else: 0)
        )
      end
    end
  end
end
