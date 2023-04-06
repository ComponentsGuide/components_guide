defmodule ComponentsGuide.Wasm.WasmExamples do
  # alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Rustler.Wasm
  alias ComponentsGuide.Rustler.WasmBuilder

  defmodule EscapeHTML do
    use Wasm

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
    use Wasm

    @strings pack_strings_nul_terminated(4,
               doctype: "<!doctype html>",
               good: "<h1>Good</h1>",
               bad: "<h1>Bad</h1>",
               content_type: "content-type: text/html;charset=utf-8\\r\\n"
             )

    # Doesn’t work because we are evaluating the block at compile time.
    def doctype do
      4
    end

    @request_body_write_offset 65536

    defwasm imports: [
              env: [buffer: memory(2)]
            ],
            exported_globals: [
              request_body_write_offset: i32(@request_body_write_offset)
            ],
            globals: [
              body_chunk_index: i32(0)
              # request_body_write_offset: i32(@request_body_write_offset)
            ] do
      data_nul_terminated(@strings)

      func get_request_body_write_offset, result: I32 do
        request_body_write_offset
      end

      func GET do
        body_chunk_index = 0
      end

      funcp get_is_valid, result: I32 do
        I32.eq(I32.load8_u(request_body_write_offset), ?g)
      end

      func get_status, result: I32 do
        # I32.if_else(call(:get_is_valid), do: 200, else: 400)
        I32.if_else call(:get_is_valid) do
          200
        else
          400
        end

        # if call(:get_is_valid) do
        #   return(200)
        # else
        #   return(400)
        # end
      end

      func get_headers, result: I32 do
        @strings.content_type.offset
      end

      func next_body_chunk, result: I32, locals: [is_valid: I32] do
        is_valid = call(:get_is_valid)
        body_chunk_index = I32.add(body_chunk_index, 1)

        # I32.if_else(I32.eq(body_chunk_index, 1),
        #   do: 4,
        #   else: I32.if_else(is_valid, do: 20, else: 40)
        # )
        # I32.if_else(I32.eq(body_chunk_index, 1),
        #   do: lookup_data(:doctype),
        #   else: I32.if_else(is_valid, do: lookup_data(:good_heading), else: lookup_data(:bad_heading))
        # )

        # br_table do
        #   1 -> 4
        #   2 ->
        #     if is_valid do
        #       @strings.good.offset
        #     else
        #       @strings.bad.offset
        #     end
        #   _ -> 0
        # end

        # I32.if_else I32.eq(body_chunk_index, 1), do: return(4)
        # I32.if_else I32.eq(body_chunk_index, 2), do: return(@strings.good.offset)
        # 0

        # if I32.eq(body_chunk_index, 1) do
        #   return(@strings.doctype.offset)
        #   # :return
        # end

        # if I32.eq(body_chunk_index, 2) do
        #   @strings.good.offset
        #   # if is_valid do
        #   #   push(@strings.good.offset)
        #   # else
        #   #   push(@strings.bad.offset)
        #   # end
        # else
        #   push(0)
        # end

        I32.if_else(I32.eq(body_chunk_index, 1),
          do: @strings.doctype.offset,
          else:
            I32.if_else(I32.eq(body_chunk_index, 2),
              do: I32.if_else(is_valid, do: @strings.good.offset, else: @strings.bad.offset),
              else: 0
            )
        )
      end
    end

    alias ComponentsGuide.Rustler.Wasm

    def get_request_body_write_offset(instance) do
      Wasm.instance_get_global(instance, "request_body_write_offset")
      # Wasm.instance_call(instance, "get_request_body_write_offset")
    end

    def set_request_body_write_offset(instance, offset) do
      Wasm.instance_set_global(instance, "request_body_write_offset", offset)
    end

    def write_string_nul_terminated(instance, offset, string) do
      Wasm.instance_write_string_nul_terminated(instance, offset, string)
    end

    def set_request_body(instance, body) do
      Wasm.instance_write_string_nul_terminated(instance, :request_body_write_offset, body)
    end

    def get(instance) do
      Wasm.instance_call(instance, "GET")
    end

    def get_status(instance) do
      Wasm.instance_call(instance, "get_status")
    end

    def get_headers(instance) do
      Wasm.instance_call_returning_string(instance, "get_headers")
    end

    def next_body_chunk(instance) do
      Wasm.instance_call_returning_string(instance, "next_body_chunk")
    end

    def all_body_chunks(instance) do
      Stream.unfold(0, fn n ->
        case Wasm.instance_call_returning_string(instance, "next_body_chunk") do
          "" -> nil
          s -> {s, n + 1}
        end
      end)
    end

    def read_body(instance) do
      all_body_chunks(instance) |> Enum.join()
    end
  end

  defmodule Counter do
    use Wasm

    defwasm imports: [
              env: [buffer: memory(1)]
            ],
            globals: [
              count: i32(0)
            ] do
      func get_current, result: I32 do
        count
      end

      func increment, result: I32 do
        count = I32.add(count, 1)
        count
      end
    end

    alias ComponentsGuide.Rustler.Wasm

    def get_current(instance) do
      Wasm.instance_call(instance, "get_current")
    end

    def increment(instance) do
      Wasm.instance_call(instance, "increment")
    end
  end

  # defmodule CounterHTMLFuture do
  #   defcomponent state: [
  #     count: 0
  #   ] do
  #     render do
  #       ~E"""
  #       <output><%= @count %></output>
  #       <button data-action="increment">Increment</button>
  #       """
  #     end

  #     action increment do
  #       %{count: count + 1}
  #       # count = count + 1
  #     end
  #   end
  # end

  defmodule CounterHTML do
    use Wasm

    @strings pack_strings_nul_terminated(0x4,
               output_start: ~S[<output class="flex p-4 bg-gray-800">],
               output_end: ~S[</output>],
               button_increment:
                 ~S[\n<button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>]
             )

    # @body deftemplate(~E"""
    #       <output class="flex p-4 bg-gray-800"><%= call(:i32toa, count) %></output>
    #       <button data-action="increment" class="mt-4 inline-block py-1 px-4 bg-white text-black rounded">Increment</button>
    #       """)

    @bump_start 1024

    defwasm imports: [
              env: [buffer: memory(1)]
            ],
            globals: [
              count: i32(0),
              body_chunk_index: i32(0),
              bump_offset: i32(@bump_start)
            ] do
      func get_current, result: I32 do
        count
      end

      func increment, result: I32 do
        count = I32.add(count, 1)
        count
      end

      data_nul_terminated(@strings)

      func invalidate, locals: [i: I32] do
        body_chunk_index = 0
        bump_offset = @bump_start

        i = 64
        defloop Clear do
          memory32_8![I32.add(i, @bump_start)] = 0x0
          i = I32.sub(i, 1)
          br(Clear, if: I32.gt_u(i, 0))
        end
      end

      funcp i32toa(value(I32)), result: I32, locals: [working_offset: I32, digit: I32] do
        # Max int is 4294967296 which has 10 digits. We add one for nul byte.
        # We “allocate” all 11 bytes upfront to make the algorithm easier.
        bump_offset = I32.add(bump_offset, 11)
        # We then start from the back, as we have to print the digits in reverse.
        working_offset = bump_offset

        defloop Digits do
          working_offset = I32.sub(working_offset, 1)

          digit = I32.rem_u(value, 10)
          value = I32.div_u(value, 10)
          memory32_8![working_offset] = I32.add(?0, digit)

          br(Digits, if: I32.gt_u(value, 0))
        end

        working_offset
      end

      func next_body_chunk, result: I32 do
        defblock Main, result: I32 do
          if I32.eq(body_chunk_index, 0) do
            push(@strings.output_start.offset)
            br(Main)
          end

          if I32.eq(body_chunk_index, 1) do
            push(count)
            call(:i32toa)
            br(Main)
          end

          if I32.eq(body_chunk_index, 2) do
            push(@strings.output_end.offset)
            br(Main)
          end

          if I32.eq(body_chunk_index, 3) do
            push(@strings.button_increment.offset)
            br(Main)
          end

          0x0
        end

        body_chunk_index = I32.add(body_chunk_index, 1)
      end
    end

    alias ComponentsGuide.Rustler.Wasm

    def get_current(instance) do
      Wasm.instance_call(instance, "get_current")
    end

    def increment(instance) do
      Wasm.instance_call(instance, "increment")
    end

    def read_body(instance) do
      Wasm.instance_call(instance, "invalidate")
      Wasm.instance_call_stream_string_chunks(instance, "next_body_chunk") |> Enum.join()
    end

    def initial_html() do
      instance = start()
      read_body(instance)
    end
  end

  defmodule Loader do
    use Wasm

    # defmodule LoadableMachine do
    #   use Machine,
    #     states: [:idle, :loading, :loaded, :failed]

    # defstate Idle do
    #   on(:start), do: Loading
    # end

    #   def on(:idle, :start), do: :loading
    #   def entry(:loading), do: :load
    #   def on(:loading, :success), do: :loaded
    #   def on(:loading, :failure), do: :failed
    # end

    defwasm imports: [
              # env: [buffer: memory(1)]
            ],
            exported_globals: [
              idle: i32(0),
              loading: i32(1),
              loaded: i32(2),
              failed: i32(3)
            ],
            globals: [
              state: i32(0)
            ] do
      # func get_current, do: state
      func get_current, result: I32 do
        state
      end

      # defstates :state do
      #   state Idle do
      #     :begin -> Loading
      #   end

      #   state Loading do
      #     :success -> Loaded
      #     :failure -> Failed
      #   end

      #   state Loaded do
      #   end

      #   state Failed do
      #   end
      # end

      func begin do
        if I32.eq(state, idle) do
          state = loading
          # {:raw_wat, ~s[(global.set $state (i32.const 1))]}

          # TODO: Call entry callback “load”
        end
      end

      func success do
        if I32.eq(state, loading) do
          state = loaded
        end
      end

      func failure do
        if I32.eq(state, loading) do
          state = failed
        end
      end
    end

    alias ComponentsGuide.Rustler.Wasm

    def get_current(instance), do: Wasm.instance_call(instance, "get_current")
    def begin(instance), do: Wasm.instance_call(instance, "begin")
    def success(instance), do: Wasm.instance_call(instance, "success")
    def failure(instance), do: Wasm.instance_call(instance, "failure")
  end
end
