defmodule ComponentsGuide.Wasm.Examples.State do
  alias ComponentsGuide.Wasm

  defmodule StateMachine do
    defmacro __using__(_opts) do
      quote do
        use Orb
        Orb.I32.global(state: 0, change_count: 0)

        import unquote(__MODULE__)

        wasm Orb.U32 do
          funcp transition_to(new_state: Orb.I32) do
            local_get(:new_state)
            global_set(:state)
            Orb.I32.add(global_get(:change_count), 1)
            global_set(:change_count)
          end

          func get_change_count(), Orb.I32 do
            global_get(:change_count)
          end
        end
      end
    end

    defmacro on(call, target: target) do
      use Orb, inline: true
      # import Orb
      # alias Orb.{I32, F32}
      import Kernel, except: [if: 2]

      {name, args} = Macro.decompose_call(call)
      [current_state] = args
      # IO.inspect(args)
      # IO.inspect(target)

      case current_state do
        # If current state is `_` i.e. being ignored.
        {:_, _, _} ->
          quote do
            func unquote(name) do
              Orb.call(:transition_to, unquote(target))
            end
          end

        # If we are checking what the current state is.
        current_state ->
          quote do
            # Module.register_attribute(__MODULE__, String.to_atom("func_#{unquote(name)}"), accumulate: true)

            func unquote(name) do
              if I32.eq(global_get(:state), unquote(current_state)) do
                Orb.call(:transition_to, unquote(target))
              end
            end
          end
      end
    end

    defmacro on(call, do: targets) do
      use Orb, inline: true
      # import Orb
      # alias Orb.{I32, F32}
      import Kernel, except: [if: 2]
      import OrbUsing

      {name, []} = Macro.decompose_call(call)

      statements =
        for {:->, _, [matches, target]} <- targets do
          effect =
            case target do
              {target, global_mutations} when is_list(global_mutations) ->
                quote do
                  [
                    unquote(target),
                    global_set(:state),
                    unquote(
                      for {global_name, mutation} <- global_mutations do
                        case mutation do
                          :increment ->
                            quote do
                              [
                                I32.add(global_get(unquote(global_name)), 1),
                                global_set(unquote(global_name))
                              ]
                            end

                          n when is_integer(n) ->
                            quote do
                              [
                                push(unquote(n)),
                                global_set(unquote(global_name))
                              ]
                            end
                        end
                      end
                    ),
                    :return
                  ]
                end

              {target, {:snippet, _, _} = snippet} ->
                quote do
                  [unquote(target), global_set(:state), unquote(snippet), :return]
                end

              target ->
                IO.inspect(target)

                quote do
                  [unquote(target), global_set(:state), :return]
                end
            end

          case matches do
            # catchall
            [{:_, _, nil}] ->
              effect

            [match] ->
              quote do
                if I32.eq(global_get(:state), unquote(match)) do
                  unquote(effect)
                end
              end

            matches ->
              quote do
                if I32.in?(global_get(:state), unquote(matches)) do
                  unquote(effect)
                end
              end
          end
        end

      quote do
        func unquote(name) do
          unquote(statements)
        end
      end
    end
  end

  # TODO: Port examples from https://xstate-catalogue.com
  # TODO: Add this file upload example https://twitter.com/jagregory/status/1449265165816393730

  defmodule Counter do
    use Wasm

    wasm_memory(pages: 1)
    # Memory.increase(pages: 1)

    I32.global(count: 0)

    wasm U32 do
      func(get_current(), I32, do: @count)

      func increment(), I32 do
        @count = @count + 1
        @count
      end
    end

    alias ComponentsGuide.Wasm.Instance

    def get_current(instance), do: Instance.call(instance, :get_current)
    def increment(instance), do: Instance.call(instance, :increment)
  end

  defmodule Loader do
    use Wasm

    use StateMachine

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

    I32.export_enum([:idle, :loading, :loaded, :failed])

    # State.transitions do
    #   @idle ->
    #     [begin: @loading]
    #     
    #   @loading ->
    #     [success: @loaded, failure: @failed]
    # end

    # State.define :state do
    #   :idle ->
    #     [begin: :loading]
    #     
    #   :loading ->
    #     [success: :loaded, failure: :failed]
    #   
    #   :loaded ->
    #     :terminal
    #     
    #   :failed ->
    #     :terminal
    # end

    wasm do
      # @idle 0
      # @loading 1
      # @loaded 2
      # @failed 3

      func(get_current(), I32, do: @state)

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
      on(begin(@idle), target: @loading)
      on(success(@loading), target: @loaded)
      on(failure(@loading), target: @failed)

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
              edited: i32(1),
              submitting: i32(2),
              succeeded: i32(3),
              failed: i32(4)
            ],
            exported_mutable_globals: [
              initial: i32(0)
            ],
            globals: [
              state: i32(0),
              edit_count: i32(0),
              submitted_edit_count: i32(0)
            ] do
      func(get_current(), I32, do: state)
      func(get_edit_count(), I32, do: edit_count)
      func(get_submitted_edit_count(), I32, do: submitted_edit_count)

      func user_can_edit?(), I32 do
        state |> I32.eq(submitting) |> I32.eqz()
      end

      func user_can_submit?(), I32 do
        state |> I32.eq(submitting) |> I32.eqz()
        # eq(state, submitting) |> eqz()
      end

      func user_did_edit() do
        # if I32.magic(state in [initial, edited]) do
        #   state = edited
        #   edit_count = I32.add(edit_count, 1)
        # end

        if I32.or(
             I32.eq(state, initial),
             I32.eq(state, edited),
             I32.eq(state, succeeded),
             I32.eq(state, failed)
           ) do
          state = edited
          edit_count = I32.add(edit_count, 1)
        end
      end

      func user_did_submit do
        if I32.eqz(I32.eq(state, submitting)) do
          state = submitting
          submitted_edit_count = edit_count
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
    use StateMachine

    @states I32.calculate_enum([:offline?, :online?])

    # defstate Offline do
    #   on(online, target: Online)
    # end
    # defstate Online do
    #   on(offline, target: Offline)
    # end

    defwasm exported_globals: [
              offline?: @states.offline?,
              online?: @states.online?,
              listen_to_window: i32(0x100)
              # listen_to_window_offline: i32(1),
              # listen_to_window_online: i32(1),
            ] do
      func(get_current(), I32, do: @state)

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
    use StateMachine

    defwasm exported_globals: [
              active: i32(0),
              inactive: i32(1)
              # listen_to_document_focusin: i32(1),
            ],
            imports: [
              conditions: [
                is_focused: func(name: :check_is_active, params: nil, result: I32)
              ]
            ] do
      func(get_current(), I32, do: @state)

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

    # Generate state machine on the fly:
    # /wasm/state-machine/Closed,Open?Closed.open=Open&Open.close=Closed&Open.cancel=Closed
    # Generate state machine on the fly with initial state Open:
    # /wasm/state-machine/Closed,Open/Open?Closed.open=Open&Open.close=Closed&Open.cancel=Closed

    @states I32.calculate_enum([:closed?, :open?])
    use StateMachine, initial: @states.closed?

    # defstatemachine [:closed?, :open?] do
    #   on(open(closed?), target: open?)
    #   on(close(open?), target: closed?)
    # end

    defwasm exported_globals: [
              closed?: @states.closed?,
              open?: @states.open?
            ] do
      func(get_current(), I32, do: @state)
      on(open(closed?), target: open?)
      on(close(open?), target: closed?)
      # See: http://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/cancel_event
      # TODO: emit did_cancel event
      on(cancel(open?), target: closed?)
    end

    alias ComponentsGuide.Wasm.Instance

    def get_current(instance), do: Instance.call(instance, :get_current)
    def open(instance), do: Instance.call(instance, :open)
    def close(instance), do: Instance.call(instance, :close)
  end

  defmodule AbortController do
    use Wasm
    use StateMachine

    defwasm exported_globals: [
              active: i32(0),
              aborted: i32(1)
            ] do
      func(aborted?(), I32, do: @state)

      on(abort(active), target: aborted)
    end

    alias ComponentsGuide.Wasm.Instance

    def aborted?(instance), do: Instance.call(instance, :aborted?)
    def abort(instance), do: Instance.call(instance, :abort)
  end

  # Or is it Future?
  defmodule Promise do
    use Wasm
    use StateMachine, initial: @states.pending

    @states I32.calculate_enum([:pending, :resolved, :rejected])

    defwasm exported_globals: [
              pending: @states.pending,
              resolved: @states.resolved,
              rejected: @states.rejected
            ] do
      func(get_current(), I32, do: @state)

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
    use StateMachine

    @states I32.calculate_enum([
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
            ] do
      func(get_current(), I32, do: @state)

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

    defwasm exported_globals: [], exported_mutable_globals: [time: i32(0)] do
      func will_send(), I32 do
        time = I32.add(time, 1)
        time
      end

      func received(incoming_time(I32)), I32 do
        if I32.gt_u(incoming_time, time) do
          time = incoming_time
        end

        time = I32.add(time, 1)
        time
      end
    end

    def read(instance), do: Instance.get_global(instance, :time)
    def received(instance, incoming_time), do: Instance.call(instance, :received, incoming_time)

    defp will_send(instance), do: Instance.call(instance, :will_send)

    def send(a, b) do
      t = will_send(a)
      received(b, t)
    end
  end

  defmodule LiveAPIConnection do
    # See: https://liveblocks.io/blog/whats-new-in-v1-1

    use Orb

    I32.enum([
      :idle_initial,
      :idle_failed,
      :auth_busy,
      :auth_backoff,
      :connecting_busy,
      :connecting_backoff,
      :ok_connected,
      :ok_awaiting_pong
    ])

    I32.export_enum([
      :initial,
      :connecting,
      :connected,
      :reconnecting,
      :disconnected
    ])

    use StateMachine, initial: :initial

    @backoff_delays [250, 500, 1000, 2000, 4000, 8000, 10000]

    # wasm_import [
    #   effects: [
    #     send_heartbeat: func(name: :send_heartbeat, params: I32, result: I32)
    #   ]
    # ]

    # I32.global(state: @initial?)

    I32.global(success_count: 0)
    I32.global(token: 0)
    I32.global(backoff_level: 0)
    # I32.global(inbox_heartbeat: 0)

    wasm_memory(pages: 1)

    # wasm_import [
    #   effects: [
    #     send_heartbeat: func(name: :send_heartbeat, params: I32, result: I32)
    #   ]
    # ]

    wasm U32 do
      func(get_search_params(), I32, do: 0x0)
      func(info_success_count(), I32, do: @success_count)

      # TODO: do this in another way?
      func(set_token(token: I32)) do
        @token = token
      end

      on reconnect() do
        _ ->
          {@auth_backoff, success_count: 0}
      end

      on disconnect() do
        _ -> @idle_initial
      end

      on connect() do
        @idle_initial, @idle_failed -> I32.when?(@token, do: @connecting_busy, else: @auth_busy)
      end

      # TODO: pass token
      on auth_succeeded() do
        @auth_busy -> @connecting_busy
      end

      on connecting_succeeded() do
        @connecting_busy ->
          {@ok_connected, success_count: :increment}
          # @connecting_busy ->
          #   {@ok_connected,
          #    snippet U32 do
          #      @success_count = @success_count + 1
          #    end}
      end

      on pong() do
        @ok_awaiting_pong -> @ok_connected
      end

      on pong_timedout() do
        @ok_awaiting_pong -> @connecting_busy
      end

      on socket_received_error() do
        @ok_connected, @ok_awaiting_pong -> {@connecting_backoff, backoff_level: 1}
      end

      func get_backoff_delay(), I32 do
        I32.match @backoff_level do
          0 -> 0
          1 -> ^Enum.at(@backoff_delays, 0)
          2 -> ^Enum.at(@backoff_delays, 1)
          3 -> ^Enum.at(@backoff_delays, 2)
          4 -> ^Enum.at(@backoff_delays, 3)
          5 -> ^Enum.at(@backoff_delays, 4)
          6 -> ^Enum.at(@backoff_delays, 5)
          _ -> ^Enum.at(@backoff_delays, 6)
        end
      end

      on navigator_offline() do
        @ok_connected -> @ok_awaiting_pong
      end

      on window_did_focus() do
        @ok_connected ->
          # {@ok_awaiting_pong, [:heartbeat]}
          @ok_awaiting_pong
      end

      func timer_ms_heartbeat(), I32 do
        I32.match @state do
          @ok_connected -> 30_000
          _ -> 0
        end
      end

      func timeout_ms_pong(), I32 do
        I32.match @state do
          @ok_awaiting_pong -> 2_000
          _ -> 0
        end
      end

      func effect_heartbeat?(), I32 do
        I32.in?(@state, [@ok_awaiting_pong])
      end

      funcp get_public_state(), I32 do
        I32.match @state do
          @idle_initial ->
            @initial

          @idle_failed ->
            @disconnected

          @auth_busy, @auth_backoff, @connecting_busy, @connecting_backoff ->
            I32.when?(@success_count > 0, do: @reconnecting, else: @connecting)

          @ok_connected ->
            @connected

          @ok_awaiting_pong ->
            @connected
        end
      end

      func(get_current(), I32, do: call(:get_public_state))

      func get_path(), I32.String, state: I32 do
        state = call(:get_public_state)

        I32.match state do
          @initial -> ~S[/initial]
          @connecting -> ~S[/connecting]
          @connected -> ~S[/connected]
          @reconnecting -> ~S[/reconnecting]
          @disconnected -> ~S[/disconnected]
        end
      end

      func get_debug_path(), I32.String do
        I32.match @state do
          @idle_initial -> ~S[/idle_initial]
          @idle_failed -> ~S[/idle_failed]
          @auth_busy -> ~S[/auth_busy]
          @auth_backoff -> ~S[/auth_backoff]
          @connecting_busy -> ~S[/connecting_busy]
          @connecting_backoff -> ~S[/connecting_backoff]
          @ok_connected -> ~S[/ok_connected]
          @ok_awaiting_pong -> ~S[/ok_awaiting_pong]
        end
      end
    end
  end

  defmodule FlightBooking do
    use Wasm

    I32.export_enum([
      :initial?,
      :destination?,
      :dates?,
      :flights?,
      :seats?,
      :checkout?,
      :checkout_failed?,
      :booked?,
      :confirmation?
    ])

    use StateMachine, initial: :initial?
    # I32.global(state: @initial?)

    wasm_memory(pages: 1)

    wasm do
      func(get_current(), I32, do: @state)
      func(get_search_params(), I32, do: 0x0)

      on next() do
        @initial? -> @destination?
        @destination? -> @dates?
        @dates? -> @flights?
        @flights? -> @seats?
      end

      func get_path(), I32.String do
        I32.match @state do
          @initial? -> ~S[/book]
          @destination? -> ~S[/destination]
          @dates? -> ~S[/dates]
          @flights? -> ~S[/flights]
          @seats? -> ~S[/seats]
        end
      end
    end
  end
end
