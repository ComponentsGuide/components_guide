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

    alias ComponentsGuide.Wasm

    def get_current(instance), do: Wasm.instance_call(instance, "get_current")
    def begin(instance), do: Wasm.instance_call(instance, "begin")
    def success(instance), do: Wasm.instance_call(instance, "success")
    def failure(instance), do: Wasm.instance_call(instance, "failure")
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
