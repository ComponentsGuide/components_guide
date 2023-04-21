defmodule ComponentsGuide.Wasm.Examples.State do
  alias ComponentsGuide.Wasm

  # Port examples from https://xstate-catalogue.com

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

    alias ComponentsGuide.Wasm

    def get_current(instance) do
      Wasm.instance_call(instance, "get_current")
    end

    def increment(instance) do
      Wasm.instance_call(instance, "increment")
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

    defwasm exported_globals: [
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

    alias ComponentsGuide.Wasm

    def get_current(instance), do: Wasm.instance_call(instance, "get_current")
    def begin(instance), do: Wasm.instance_call(instance, "begin")
    def success(instance), do: Wasm.instance_call(instance, "success")
    def failure(instance), do: Wasm.instance_call(instance, "failure")
  end

  defmodule Form do
    use Wasm

    defwasm exported_globals: [
              initial: i32(0),
              edited: i32(1),
              submitting: i32(2),
              succeeded: i32(3),
              failed: i32(4)
            ],
            globals: [
              state: i32(0),
              edit_count: i32(0)
            ] do
      # func get_current, do: state
      func get_current, result: I32 do
        state
      end

      func get_edit_count, result: I32 do
        edit_count
      end

      func can_submit, result: I32 do
        state |> I32.eq(submitting) |> I32.eqz()
        # eq(state, submitting) |> eqz()
      end

      func did_edit do
        # if I32.go(state in [initial, edited]) do
        #   state = edited
        #   edit_count = I32.add(edit_count, 1)
        # end

        if I32.or(I32.eq(state, initial), I32.eq(state, edited)) do
          state = edited
          edit_count = I32.add(edit_count, 1)
        end
      end

      func did_submit do
        if I32.eqz(I32.eq(state, submitting)) do
          state = submitting
        end
      end

      func did_succeed do
        if I32.eq(state, submitting) do
          state = succeeded
        end
      end

      func did_fail do
        if I32.eq(state, submitting) do
          state = failed
        end
      end
    end

    alias ComponentsGuide.Wasm.Instance

    def get_current(instance), do: Instance.call(instance, "get_current")
    def get_edit_count(instance), do: Instance.call(instance, "get_edit_count")
    def did_edit(instance), do: Instance.call(instance, "did_edit")
    def did_submit(instance), do: Instance.call(instance, "did_submit")
    def did_succeed(instance), do: Instance.call(instance, "did_succeed")
    def did_fail(instance), do: Instance.call(instance, "did_fail")
  end

  defmodule LamportClock do
    use Wasm

    defwasm exported_globals: [time: i32(0)] do
      func will_send(), result: I32 do
        time = I32.add(time, 1)
        time
      end

      func received(incoming_time(I32)), result: I32 do
        if I32.gt_u(incoming_time, time) do
          time = incoming_time
        end

        time = I32.add(time, 1)
        time
      end
    end

    def read(instance) do
      Wasm.instance_get_global(instance, :time)
    end

    def will_send(instance) do
      Wasm.instance_call(instance, "will_send")
    end

    def send(a, b) do
      t = will_send(a)
      received(b, t)
    end

    def received(instance, incoming_time) do
      Wasm.instance_call(instance, "received", incoming_time)
    end
  end
end
