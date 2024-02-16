defmodule ComponentsGuide.Wasm.Examples.State do
  alias OrbWasmtime.Instance

  defmodule StateMachine do
    defmacro __using__(_opts) do
      quote do
        use Orb

        alias Orb.Instruction

        Orb.I32.global(state: 0, change_count: 0)

        import unquote(__MODULE__)

        defwp transition_to(new_state: Orb.I32) do
          Instruction.global_set(Orb.I32, :state, Instruction.local_get(Orb.I32, :new_state))

          Instruction.global_set(
            Orb.I32,
            :change_count,
            Orb.I32.add(Instruction.global_get(Orb.I32, :change_count), 1)
          )
        end

        defw get_change_count(), Orb.I32 do
          Instruction.global_get(Orb.I32, :change_count)
        end
      end
    end

    defmacro on(call, target: target) do
      alias Orb.I32
      require Orb.IfElse.DSL

      {name, args} = Macro.decompose_call(call)
      [current_state] = args

      case current_state do
        # If current state is `_` i.e. being ignored.
        {:_, _, _} ->
          quote do
            Orb.__append_body do
              func unquote(Macro.escape(name)) do
                transition_to(unquote(target))
                # Orb.DSL.typed_call(nil, :transition_to, [unquote(target)])
              end
            end
          end

        # If we are checking what the current state is.
        current_state ->
          quote do
            alias Orb.Instruction

            # Module.register_attribute(__MODULE__, String.to_atom("func_#{unquote(name)}"), accumulate: true)

            Orb.__append_body do
              func unquote(Macro.escape(name)) do
                Orb.IfElse.DSL.if I32.eq(
                                    Instruction.global_get(Orb.I32, :state),
                                    unquote(current_state)
                                  ) do
                  transition_to(unquote(target))
                  # Orb.DSL.typed_call(nil, :transition_to, [unquote(target)])
                end
              end
            end
          end
      end
    end

    defmacro on(call, do: targets) do
      alias Orb.I32
      alias Orb.Instruction
      require Orb.IfElse.DSL

      {name, []} = Macro.decompose_call(call)

      statements =
        for {:->, _, [matches, target]} <- targets do
          effect =
            case target do
              {target, global_mutations} when is_list(global_mutations) ->
                quote do
                  [
                    Instruction.global_set(Orb.I32, :state, unquote(target)),
                    unquote(
                      for {global_name, mutation} <- global_mutations do
                        case mutation do
                          :increment ->
                            quote do
                              Instruction.global_set(
                                Orb.I32,
                                unquote(global_name),
                                I32.add(Instruction.global_get(Orb.I32, unquote(global_name)), 1)
                              )
                            end

                          n when is_integer(n) ->
                            quote do
                              Instruction.global_set(Orb.I32, unquote(global_name), unquote(n))
                            end
                        end
                      end
                    ),
                    :return
                  ]
                end

              {target, {:snippet, _, _} = snippet} ->
                quote do
                  [
                    Instruction.global_set(Orb.I32, :state, unquote(target)),
                    unquote(snippet),
                    :return
                  ]
                end

              target ->
                IO.inspect(target)

                quote do
                  [Instruction.global_set(Orb.I32, :state, unquote(target)), :return]
                end
            end

          case matches do
            # catchall
            [{:_, _, nil}] ->
              effect

            [match] ->
              quote do
                Orb.IfElse.DSL.if I32.eq(Instruction.global_get(Orb.I32, :state), unquote(match)) do
                  unquote(effect)
                end
              end

            matches ->
              quote do
                Orb.IfElse.DSL.if I32.in?(
                                    Instruction.global_get(Orb.I32, :state),
                                    unquote(matches)
                                  ) do
                  unquote(effect)
                end
              end
          end
        end

      quote do
        Orb.__append_body do
          func unquote(name) do
            unquote(statements)
          end
        end
      end
    end
  end

  # TODO: Port examples from https://xstate-catalogue.com
  # TODO: Add this file upload example https://twitter.com/jagregory/status/1449265165816393730

  defmodule Counter do
    use Orb

    Memory.pages(1)
    # Memory.increase(pages: 1)

    I32.global(count: 0)

    defw(get_current(), I32, do: @count)

    defw increment(), I32 do
      @count = @count + 1
      @count
    end

    def get_current(instance), do: Instance.call(instance, :get_current)
    def increment(instance), do: Instance.call(instance, :increment)
  end

  defmodule Loader do
    use Orb
    use StateMachine

    I32.export_enum([:idle, :loading, :loaded, :failed])

    defw(get_current(), I32, do: @state)

    on(load(@idle), target: @loading)
    on(success(@loading), target: @loaded)
    on(failure(@loading), target: @failed)

    def get_current(instance), do: Instance.call(instance, :get_current)
    def load(instance), do: Instance.call(instance, :load)
    def success(instance), do: Instance.call(instance, :success)
    def failure(instance), do: Instance.call(instance, :failure)
  end

  defmodule Form do
    use Orb

    # global do
    #   @initial 0
    # end
    # globalp do
    #   @state 0
    #   @edit_count 0
    #   @submitted_edit_count 0
    # end

    # global_enum 1 do
    #   @edited
    #   @submitting
    #   @succeeded
    #   @failed
    # end

    I32.export_enum([:edited, :submitting, :succeeded, :failed], 1)
    I32.export_global(:mutable, initial: 0)
    I32.global(state: 0, edit_count: 0, submitted_edit_count: 0)

    defw(get_current(), I32, do: @state)
    defw(get_edit_count(), I32, do: @edit_count)
    defw(get_submitted_edit_count(), I32, do: @submitted_edit_count)

    defw user_can_edit?(), I32 do
      @state |> I32.eq(@submitting) |> I32.eqz()
    end

    defw user_can_submit?(), I32 do
      @state |> I32.eq(@submitting) |> I32.eqz()
      # eq(@state, @submitting) |> eqz()
    end

    defw user_did_edit() do
      # if I32.magic(state in [initial, edited]) do
      #   state = edited
      #   edit_count = I32.add(edit_count, 1)
      # end

      if I32.in?(@state, [@initial, @edited, @succeeded, @failed]) do
        @state = @edited
        @edit_count = I32.add(@edit_count, 1)
      end
    end

    defw user_did_submit do
      # TODO: use I32.ne()
      if I32.eqz(I32.eq(@state, @submitting)) do
        @state = @submitting
        @submitted_edit_count = @edit_count
      end
    end

    defw destination_did_succeed do
      if I32.eq(@state, @submitting) do
        @state = @succeeded
      end
    end

    defw destination_did_fail do
      if I32.eq(@state, @submitting) do
        @state = @failed
      end
    end

    # def get_current(instance), do: Instance.call(instance, "get_current")
    # def get_edit_count(instance), do: Instance.call(instance, "get_edit_count")
    def user_did_edit(instance), do: Instance.call(instance, "user_did_edit")
    def user_did_submit(instance), do: Instance.call(instance, "user_did_submit")
    def destination_did_succeed(instance), do: Instance.call(instance, "destination_did_succeed")
    def destination_did_fail(instance), do: Instance.call(instance, "destination_did_fail")
  end

  defmodule OfflineStatus do
    use Orb
    use StateMachine

    # defstate Offline do
    #   on(online, target: Online)
    # end
    # defstate Online do
    #   on(offline, target: Offline)
    # end

    I32.export_enum([:offline?, :online?])
    I32.export_global(:readonly, listen_to_window: 0x100)
    # listen_to_window_offline: 1,
    # listen_to_window_online: 1,

    defw(get_current(), I32, do: @state)

    on(online(@offline?), target: @online?)
    on(offline(@online?), target: @offline?)

    def get_current(instance), do: Instance.call(instance, :get_current)
    def offline(instance), do: Instance.call(instance, :offline)
    def online(instance), do: Instance.call(instance, :online)
  end

  defmodule FocusListener do
    use Orb
    use StateMachine

    I32.export_enum([:active, :inactive])

    defmodule Conditions do
      use Orb.Import

      defw(is_focused(), I32)
    end

    importw(Conditions, :conditions)

    # wasm_import(:conditions,
    #   is_focused: Orb.DSL.funcp(name: :check_is_active, params: nil, result: I32)
    # )

    defw(get_current(), I32, do: @state)

    # on(focusin(active), ask: :check_is_active, true: active, false: inactive)
    on(focus(@inactive), target: @active)

    def get_current(instance), do: Instance.call(instance, :get_current)
    def offline(instance), do: Instance.call(instance, :offline)
    def online(instance), do: Instance.call(instance, :online)
  end

  defmodule Dialog do
    use Orb

    # Generate state machine on the fly:
    # /wasm/state-machine/Closed,Open?Closed.open=Open&Open.close=Closed&Open.cancel=Closed
    # Generate state machine on the fly with initial state Open:
    # /wasm/state-machine/Closed,Open/Open?Closed.open=Open&Open.close=Closed&Open.cancel=Closed

    use StateMachine, initial: 0

    # defstatemachine [:closed?, :open?] do
    #   on(open(closed?), target: open?)
    #   on(close(open?), target: closed?)
    # end

    I32.export_enum([:closed?, :open?])

    defw(get_current(), I32, do: @state)
    on(open(@closed?), target: @open?)
    on(close(@open?), target: @closed?)
    # See: http://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement/cancel_event
    # TODO: emit did_cancel event
    on(cancel(@open?), target: @closed?)

    def get_current(instance), do: Instance.call(instance, :get_current)
    def open(instance), do: Instance.call(instance, :open)
    def close(instance), do: Instance.call(instance, :close)
  end

  defmodule AbortController do
    use Orb
    use StateMachine

    I32.export_enum([:active, :aborted])

    defw(aborted?(), I32, do: @state)
    on(abort(@active), target: @aborted)

    def aborted?(instance), do: Instance.call(instance, :aborted?)
    def abort(instance), do: Instance.call(instance, :abort)
  end

  # Or is it Future?
  defmodule Promise do
    use Orb
    use StateMachine, initial: 0
    # use StateMachine, [:pending, :resolved, :rejected], initial: :pending

    I32.export_enum([:pending, :resolved, :rejected])

    defw(get_current(), I32, do: @state)

    on(resolve(@pending), target: @resolved)
    on(reject(@pending), target: @rejected)

    def get_current(instance), do: Instance.call(instance, :get_current)
    def resolve(instance), do: Instance.call(instance, :resolve)
    def reject(instance), do: Instance.call(instance, :reject)
  end

  defmodule CSSTransition do
    use Orb
    use StateMachine

    I32.export_enum([:initial?, :started?, :canceled?, :ended?])

    defw(get_current(), I32, do: @state)

    on(transitionstart(_), target: @started?)
    on(transitioncancel(_), target: @canceled?)
    on(transitionend(_), target: @ended?)

    def get_current(instance), do: Instance.call(instance, :get_current)
    def transitionstart(instance), do: Instance.call(instance, :transitionstart)
    def transitioncancel(instance), do: Instance.call(instance, :transitioncancel)
    def transitionend(instance), do: Instance.call(instance, :transitionend)
  end

  defmodule LamportClock do
    use Orb
    alias OrbWasmtime.Instance

    I32.export_global(:mutable, time: 0)

    defw will_send(), I32 do
      @time = I32.add(@time, 1)
      @time
    end

    defw received(incoming_time: I32), I32 do
      if incoming_time > @time do
        @time = incoming_time
      end

      # if Orb.DSL.global_get(:incoming_time) > Orb.DSL.global_get(:time) do
      #   Orb.DSL.global_get(:incoming_time)
      #   Orb.DSL.global_set(:time)
      # end

      @time = @time + 1
      @time
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
    use SilverOrb.BumpAllocator

    SilverOrb.BumpAllocator.export_alloc()

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

    Memory.pages(1)

    # wasm_import [
    #   effects: [
    #     send_heartbeat: func(name: :send_heartbeat, params: I32, result: I32)
    #   ]
    # ]

    defw(get_search_params(), I32, do: 0x0)
    defw(info_success_count(), I32, do: @success_count)

    # TODO: do this in another way?
    defw set_token(token: I32) do
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

    defw get_backoff_delay(), I32 do
      I32.match @backoff_level do
        0 -> 0
        1 -> inline(do: Enum.at(@backoff_delays, 0))
        2 -> inline(do: Enum.at(@backoff_delays, 1))
        3 -> inline(do: Enum.at(@backoff_delays, 2))
        4 -> inline(do: Enum.at(@backoff_delays, 3))
        5 -> inline(do: Enum.at(@backoff_delays, 4))
        6 -> inline(do: Enum.at(@backoff_delays, 5))
        _ -> inline(do: Enum.at(@backoff_delays, 6))
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

    defw timer_ms_heartbeat(), I32 do
      I32.match @state do
        @ok_connected -> 30_000
        _ -> 0
      end
    end

    defw timeout_ms_pong(), I32 do
      I32.match @state do
        @ok_awaiting_pong -> 2_000
        _ -> 0
      end
    end

    defw effect_heartbeat?(), I32 do
      I32.in?(@state, [@ok_awaiting_pong])
    end

    defwp get_public_state(), I32 do
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

    defw(get_current(), I32, do: get_public_state())

    defw get_path(), I32.String, state: I32 do
      state = get_public_state()

      I32.match state do
        @initial -> ~S[/initial]
        @connecting -> ~S[/connecting]
        @connected -> ~S[/connected]
        @reconnecting -> ~S[/reconnecting]
        @disconnected -> ~S[/disconnected]
      end
    end

    defw get_debug_path(), I32.String do
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

  defmodule FlightBooking do
    use Orb

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

    Memory.pages(1)

    defw(get_current(), I32, do: @state)
    defw(get_search_params(), I32, do: 0x0)

    on next() do
      @initial? -> @destination?
      @destination? -> @dates?
      @dates? -> @flights?
      @flights? -> @seats?
    end

    defw get_path(), I32.String do
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
