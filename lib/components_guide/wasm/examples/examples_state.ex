defmodule ComponentsGuide.Wasm.Examples.State do
  alias ComponentsGuide.Wasm

  defmodule StateMachine do
    defmacro on(call, target: target) do
      use ComponentsGuide.WasmBuilder
      # import ComponentsGuide.WasmBuilder
      # alias ComponentsGuide.WasmBuilder.{I32, F32}
      import Kernel, except: [if: 2]
      import ComponentsGuide.WasmBuilderUsing

      {name, args} = Macro.decompose_call(call)
      [current_state] = args
      # IO.inspect(args)
      # IO.inspect(target)

      case current_state do
        {:_, _, _} ->
          quote do
            func unquote(name) do
              [unquote(target), global_set(:state)]
            end
          end

        _other ->
          quote do
            func unquote(name) do
              if I32.eq(global_get(:state), unquote(current_state)) do
                [unquote(target), global_set(:state)]
              end
            end
          end
      end
    end
  end

  # TODO: Port examples from https://xstate-catalogue.com
  # TODO: Add this file upload example https://twitter.com/jagregory/status/1449265165816393730

  defmodule Counter do
    use Wasm
    alias Wasm.Instance

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

    def get_current(instance), do: Instance.call(instance, :get_current)
    def increment(instance), do: Instance.call(instance, :increment)
  end

  defmodule Loader do
    use Wasm

    import StateMachine

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

    #   on succeeded(:loading), do: :loaded
    #   on failed(:loading), do: :failed
    # end

    defwasm exported_globals: [
              idle: i32(0),
              loading: i32(1),
              loaded: i32(2),
              failed: i32(3)
              # failed_timed_out
              # failed_network_error
              # failed_bad_response
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

      # on(begin(idle), target: loading, action: :load)
      # on(begin(idle -> loading, action: :load))
      on(begin(idle), target: loading)
      on(success(loading), target: loaded)
      on(failure(loading), target: failed)

      # state_machine state do
      #   idle ->
      #     on(begin, target: loading)

      #   loading ->
      #     on(success, target: loaded)
      #     on(failure, target: failed)

      #   loaded ->
      #     nil

      #   failed ->
      #     nil
      # end

      # func begin do
      #   if I32.eq(state, idle) do
      #     state = loading
      #     # {:raw_wat, ~s[(global.set $state (i32.const 1))]}

      #     # TODO: Call entry callback “load”
      #   end
      # end

      # func success do
      #   if I32.eq(state, loading) do
      #     state = loaded
      #   end
      # end

      # func failure do
      #   if I32.eq(state, loading) do
      #     state = failed
      #   end
      # end
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

      func user_can_submit, result: I32 do
        state |> I32.eq(submitting) |> I32.eqz()
        # eq(state, submitting) |> eqz()
      end

      func user_did_edit do
        # if I32.magic(state in [initial, edited]) do
        #   state = edited
        #   edit_count = I32.add(edit_count, 1)
        # end

        if I32.or(I32.eq(state, initial), I32.eq(state, edited)) do
          state = edited
          edit_count = I32.add(edit_count, 1)
        end
      end

      func user_did_submit do
        if I32.eqz(I32.eq(state, submitting)) do
          state = submitting
        end
      end

      func destination_did_succeed do
        if I32.eq(state, submitting) do
          state = succeeded
        end
      end

      func destination_did_fail do
        if I32.eq(state, submitting) do
          state = failed
        end
      end
    end

    alias ComponentsGuide.Wasm.Instance

    # def get_current(instance), do: Instance.call(instance, "get_current")
    # def get_edit_count(instance), do: Instance.call(instance, "get_edit_count")
    def user_did_edit(instance), do: Instance.call(instance, "user_did_edit")
    def user_did_submit(instance), do: Instance.call(instance, "user_did_submit")
    def destination_did_succeed(instance), do: Instance.call(instance, "destination_did_succeed")
    def destination_did_fail(instance), do: Instance.call(instance, "destination_did_fail")
  end

  defmodule OfflineStatus do
    use Wasm
    import StateMachine

    defwasm exported_globals: [
              # Allow setting initial state
              state: i32(0),
              offline?: i32(0),
              online?: i32(1),
              listen_to_window: i32(1)
              # listen_to_window_offline: i32(1),
              # listen_to_window_online: i32(1),
              # memory: memory_with_data("navigator.onLine\0")
            ] do
      func get_current, result: I32 do
        state
      end

      on(online(offline?), target: online?)
      on(offline(online?), target: offline?)
    end

    alias ComponentsGuide.Wasm.Instance

    def get_current(instance), do: Instance.call(instance, :get_current)
    def offline(instance), do: Instance.call(instance, :offline)
    def online(instance), do: Instance.call(instance, :online)
  end

  defmodule FocusListener do
    use Wasm
    import StateMachine

    defwasm exported_globals: [
              active: i32(0),
              inactive: i32(1)
              # listen_to_document_focusin: i32(1),
              # memory: memory_with_data("ownerDocument.activeElement\0")
            ],
            imports: [
              conditions: [
                is_focused: func(name: :check_is_active, params: nil, result: I32)
              ]
            ],
            globals: [
              state: i32(0)
            ] do
      func get_current, result: I32 do
        state
      end

      # on(focusin(active), ask: :check_is_active, true: active, false: inactive)
      on(focus(inactive), target: active)
    end

    alias ComponentsGuide.Wasm.Instance

    def get_current(instance), do: Instance.call(instance, :get_current)
    def offline(instance), do: Instance.call(instance, :offline)
    def online(instance), do: Instance.call(instance, :online)
  end

  defmodule Dialog do
    use Wasm
    import StateMachine

    @states %{
      closed?: i32(0),
      open?: i32(1)
    }

    # defstatemachine [:closed?, :open?] do
    #   on(open(closed?), target: open?)
    #   on(close(open?), target: closed?)
    # end

    defwasm exported_globals: [
              closed?: @states.closed?,
              open?: @states.open?
            ],
            globals: [
              state: @states.closed?
            ] do
      func get_current, result: I32 do
        state
      end

      on(open(closed?), target: open?)
      on(close(open?), target: closed?)
    end

    alias ComponentsGuide.Wasm.Instance

    def get_current(instance), do: Instance.call(instance, :get_current)
    def open(instance), do: Instance.call(instance, :open)
    def close(instance), do: Instance.call(instance, :close)
  end

  defmodule AbortController do
    use Wasm
    import StateMachine

    defwasm exported_globals: [
              idle: i32(0),
              aborted: i32(1)
            ],
            globals: [
              state: i32(0)
            ] do
      # func aborted?, do: state
      func aborted?, result: I32 do
        state
      end

      on(abort(idle), target: aborted)
    end

    alias ComponentsGuide.Wasm.Instance

    def aborted?(instance), do: Instance.call(instance, :aborted?)
    def abort(instance), do: Instance.call(instance, :abort)
  end

  # Or is it Future?
  defmodule Promise do
    use Wasm
    import StateMachine

    defwasm exported_globals: [
              pending: i32(0),
              resolved: i32(1),
              rejected: i32(2)
            ],
            globals: [
              state: i32(0)
            ] do
      func get_current, result: I32 do
        state
      end

      on(resolve(pending), target: resolved)
      on(reject(pending), target: rejected)
    end

    alias ComponentsGuide.Wasm.Instance

    def get_current(instance), do: Instance.call(instance, :get_current)
    def resolve(instance), do: Instance.call(instance, :resolve)
    def reject(instance), do: Instance.call(instance, :reject)
  end

  defmodule CSSTransition do
    use Wasm
    import StateMachine

    @states I32.enum([
              :initial?,
              :started?,
              :canceled?,
              :ended?
            ])

    defwasm exported_globals: [
              initial?: @states.initial?,
              started?: @states.started?,
              canceled?: @states.canceled?,
              ended?: @states.ended?
            ],
            globals: [
              state: @states.initial?
            ] do
      func get_current, result: I32 do
        state
      end

      on(transitionstart(_), target: started?)
      on(transitioncancel(_), target: canceled?)
      on(transitionend(_), target: ended?)
    end

    alias ComponentsGuide.Wasm.Instance

    def get_current(instance), do: Instance.call(instance, :get_current)
    def transitionstart(instance), do: Instance.call(instance, :transitionstart)
    def transitioncancel(instance), do: Instance.call(instance, :transitioncancel)
    def transitionend(instance), do: Instance.call(instance, :transitionend)
  end

  defmodule LamportClock do
    use Wasm
    alias Wasm.Instance

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
      Instance.get_global(instance, :time)
    end

    defp will_send(instance) do
      Instance.call(instance, :will_send)
    end

    def send(a, b) do
      t = will_send(a)
      received(b, t)
    end

    def received(instance, incoming_time) do
      Instance.call(instance, :received, incoming_time)
    end
  end
end
