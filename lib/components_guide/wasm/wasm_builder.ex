# TODO: rename to Orb
defmodule ComponentsGuide.WasmBuilder do
  alias ComponentsGuide.Wasm.Ops
  require Ops

  defmacro __using__(opts) do
    inline? = Keyword.get(opts, :inline, false)

    attrs =
      case inline? do
        true ->
          nil

        false ->
          quote do
            @before_compile unquote(__MODULE__).BeforeCompile
          end
      end

    quote do
      import ComponentsGuide.WasmBuilder
      alias ComponentsGuide.WasmBuilder.{I32, U32, F32}
      require ComponentsGuide.WasmBuilder.I32

      # @wasm_name __MODULE__ |> Module.split() |> List.last()
      # @before_compile {unquote(__MODULE__), :register_attributes}

      # unless unquote(inline?) do
      #   @before_compile unquote(__MODULE__).BeforeCompile
      # end

      unquote(attrs)

      if Module.open?(__MODULE__) do
        # @before_compile unquote(__MODULE__).BeforeCompile
        # Module.put_attribute(__MODULE__, :before_compile, unquote(__MODULE__).BeforeCompile)

        Module.put_attribute(__MODULE__, :wasm_name, __MODULE__ |> Module.split() |> List.last())

        Module.register_attribute(__MODULE__, :wasm_memory, accumulate: true)

        # FIXME: clean up these names and decide if it should be one attribute or many.
        Module.register_attribute(__MODULE__, :wasm_global, accumulate: true)
        Module.register_attribute(__MODULE__, :wasm_internal_globals, accumulate: true)
        Module.register_attribute(__MODULE__, :wasm_global_exported_readonly, accumulate: true)

        Module.register_attribute(__MODULE__, :wasm_exported_mutable_global_types,
          accumulate: true
        )

        Module.register_attribute(__MODULE__, :wasm_imports, accumulate: true)
        Module.register_attribute(__MODULE__, :wasm_body, accumulate: true)
        # @wasm_memory 0
      end
    end
  end

  defmodule Param do
    defstruct [:name, :type]
  end

  defmodule Func do
    defstruct [:name, :params, :result, :local_types, :body, :exported?]
  end

  defmodule FuncType do
    defstruct [:name, :param_types, :result_type]

    # TODO: should this be its own struct type?
    def imported_func(name, params, result_type) do
      # param_types = [:i32]
      %__MODULE__{
        name: name,
        param_types: expand_type(params),
        result_type: {:result, expand_type(result_type)}
      }
    end

    defp expand_type(type) do
      case Macro.expand_literals(type, __ENV__) do
        ComponentsGuide.WasmBuilder.I32 -> :i32
        ComponentsGuide.WasmBuilder.F32 -> :f32
        _ -> type
      end
    end
  end

  defmodule ModuleDefinition do
    defstruct name: nil,
              imports: [],
              memory: nil,
              exported_globals: [],
              exported_mutable_global_types: [],
              globals: [],
              body: []

    def new(options) do
      {body, options} = Keyword.pop(options, :body)

      {func_refs, other} = Enum.split_with(body, &match?({:mod_funcp_ref, _, _}, &1))

      func_refs =
        func_refs
        |> Enum.uniq()
        |> Enum.map(&resolve_func_ref/1)

      body = func_refs ++ other

      options = Keyword.put(options, :body, body)

      options = Keyword.update(options, :imports, [], &List.wrap/1)

      struct!(__MODULE__, options)
    end

    defp resolve_func_ref({:mod_funcp_ref, mod, name}) do
      fetch_funcp!(mod.__wasm_module__(), name)
    end

    defmodule FetchFuncError do
      defexception [:func_name, :module_definition]

      @impl true
      def message(%{func_name: func_name, module_definition: module_definition}) do
        "func #{func_name} not found in #{module_definition.name} #{inspect(module_definition.body)}"
      end
    end

    def fetch_funcp!(%__MODULE__{body: body} = module_definition, name) do
      body = List.flatten(body)

      # func = Enum.find(body, &match?(%Func{name: ^name}, &1))
      func =
        Enum.find_value(body, fn
          %Func{name: ^name} = func -> %{func | exported?: false}
          _ -> false
        end)

      func || raise FetchFuncError, func_name: name, module_definition: module_definition
    end

    def funcp_ref!(mod, name) when is_atom(mod) do
      {:mod_funcp_ref, mod, name}
    end
  end

  defmodule Import do
    defstruct [:module, :name, :type]
  end

  defmodule Memory do
    defstruct name: "", min: 0, exported?: false

    def from(nil), do: nil

    def from(list) when is_list(list) do
      case Enum.sum(list) do
        0 ->
          nil

        _min ->
          %__MODULE__{min: Enum.sum(list)}
      end
    end
  end

  defmodule Data do
    defstruct [:offset, :value, :nul_terminated]
  end

  defmodule Global do
    defstruct [:name, :type, :initial_value, :exported]

    def new(name, exported, {:i32_const, value})
        when is_atom(name) and exported in ~w[internal exported]a do
      %__MODULE__{
        name: name,
        type: :i32,
        initial_value: value,
        exported: exported == :exported
      }
    end
  end

  defmodule IfElse do
    defstruct [:result, :condition, :when_true, :when_false]

    # def new(:i32, condition, {:i32_const, a}, {:i32_const, b}) do
    #   [
    #     a,
    #     b,
    #     condition,
    #     :select!
    #   ]
    # end

    def new(result, condition, when_true, when_false) do
      %__MODULE__{
        result: result,
        condition: condition,
        when_true: when_true,
        when_false: when_false
      }
    end

    def detecting_result_type(condition, when_true, when_false) do
      result =
        case when_true do
          # TODO: detect actual type instead of assuming i32
          # [{:return, _value}] -> :i32
          _ -> nil
        end

      %__MODULE__{
        result: result,
        condition: condition,
        when_true: when_true,
        when_false: when_false
      }
    end
  end

  defmodule Loop do
    defstruct [:identifier, :result, :body]
  end

  defmodule Block do
    defstruct [:identifier, :result, :body]
  end

  defmodule I32 do
    import Kernel, except: [and: 2, or: 2]

    require Ops

    # TODO: add math macro?
    # e.g. I32.math(do: max - min + 1) gets transformed into I32.add(I32.sub(max, min), 1)

    def add(a, b)
    def sub(a, b)
    def mul(a, b)
    def div_u(a, divisor)
    def div_s(a, divisor)
    def rem_u(a, divisor)
    def rem_s(a, divisor)
    def unquote(:and_)(a, b)
    def unquote(:or)(a, b)
    def xor(a, b)
    def shl(a, b)
    def shr_u(a, b)
    def shr_s(a, b)
    def rotl(a, b)
    def rotr(a, b)

    for op <- Ops.i32(1) do
      def unquote(op)(a) do
        {:i32, unquote(op), a}
      end
    end

    for op <- Ops.i32(2) do
      case op do
        :and ->
          def and_(a, b) do
            {:i32, unquote(op), {a, b}}
          end

        _ ->
          def unquote(op)(a, b) do
            {:i32, unquote(op), {a, b}}
          end
      end
    end

    # TODO: not sure if I want to keep this pop-from-stack style.
    # It’s only used by one test.
    def eqz(), do: {:i32, :eqz}

    for op <- Ops.i32(:load) do
      def unquote(op)(offset) do
        {:i32, unquote(op), offset}
      end
    end

    for op <- Ops.i32(:store) do
      def unquote(op)(offset, value) do
        {:i32, unquote(op), offset, value}
      end
    end

    def memory8!(offset) do
      %{
        unsigned: {:i32, :load8_u, offset},
        signed: {:i32, :load8_s, offset}
      }
    end

    defp _or(a, b), do: {:i32, :or, {a, b}}
    def unquote(:or)(a, b, c), do: _or(a, _or(b, c))
    # def unquote(:or)(a, b, c, d), do: _or(a, _or(b, _or(c, d)))
    def unquote(:or)(a, b, c, d), do: a |> _or(b |> _or(c |> _or(d)))

    # def unquote(:or)(items) when is_list(items) do
    #   Enum.reduce(items, &_or/2)
    # end

    def add(items) when is_list(items) do
      Enum.reduce(items, &add/2)
    end

    def in_inclusive_range?(value, lower, upper) do
      __MODULE__.and_(I32.ge_u(value, lower), I32.le_u(value, upper))
    end

    def in?(value, list) when is_list(list) do
      # FIXME: this is pushing everything onto the stack, and then doing a massive
      # sequence of `or` to flatten them down.
      # Try to do the `or` after each value.

      for(item <- list, do: eq(value, item))
      |> Enum.reduce(&_or/2)
    end

    # defmodule U32 do
    #   def rem(a, b), do: {:i32, :rem_u, {a, b}}
    # end

    def do_u(items) do
      # import Kernel
      # import Kernel, except: [rem: 2]
      # import Unsigned

      Macro.prewalk(items, fn
        # Allow values known at compile time to be executed at compile-time by Elixir
        node = {:+, _, [a, b]} when Kernel.and(is_integer(a), is_integer(b)) ->
          node

        {:+, meta, [a, b]} ->
          {:{}, meta, [:i32, :add, {a, b}]}

        node = {:-, _, [a, b]} when Kernel.and(is_integer(a), is_integer(b)) ->
          node

        {:-, meta, [a, b]} ->
          {:{}, meta, [:i32, :sub, {a, b}]}

        node = {:/, _, [a, b]} when Kernel.and(is_integer(a), is_integer(b)) ->
          node

        {:/, meta, [a, b]} ->
          {:{}, meta, [:i32, :div_u, {a, b}]}

        {:<=, meta, [a, b]} ->
          {:{}, meta, [:i32, :le_u, {a, b}]}

        {:>=, meta, [a, b]} ->
          {:{}, meta, [:i32, :ge_u, {a, b}]}

        {:<, meta, [a, b]} ->
          {:{}, meta, [:i32, :lt_u, {a, b}]}

        {:>, meta, [a, b]} ->
          {:{}, meta, [:i32, :gt_u, {a, b}]}

        {:>>>, meta, [a, b]} ->
          {:{}, meta, [:i32, :shr_u, {a, b}]}

        {:&&&, meta, [a, b]} ->
          {:{}, meta, [:i32, :and, {a, b}]}

        {:rem, meta, [a, b]} ->
          {:{}, meta, [:i32, :rem_u, {a, b}]}

        {{:., _, [Access, :get]}, _, [{:memory32_8!, _, nil}, offset]} ->
          quote do: {:i32, :load8_u, unquote(offset)}

        other ->
          other
      end)
    end

    defmacro u!(do: expression) do
      # import Kernel, except: [rem: 2]
      # import Unsigned

      quote do
        unquote(do_u(get_block_items(expression)))
      end
    end

    defmacro u!(expression) do
      # import Kernel, except: [rem: 2]
      # import Unsigned

      quote do
        unquote(do_u(expression))
      end
    end

    defmacro when?(condition, do: when_true, else: when_false) do
      quote do
        IfElse.new(
          :i32,
          unquote(condition),
          unquote(get_block_items(when_true)),
          unquote(get_block_items(when_false))
        )
      end
    end

    # This only works with WebAssembly 1.1
    # Sadly wat2wasm doesn’t like it
    def select(condition, do: when_true, else: when_false) do
      [
        when_true,
        when_false,
        condition,
        :select
      ]
    end

    def if_else(condition, do: when_true, else: when_false) do
      %IfElse{result: :i32, condition: condition, when_true: when_true, when_false: when_false}
    end

    def if_else(condition, do: when_true) do
      %IfElse{result: :i32, condition: condition, when_true: when_true, when_false: nil}
    end

    def if_eqz(value, do: when_true, else: when_false) do
      if_else(eqz(value), do: when_true, else: when_false)
    end

    def if_eqz(value, do: when_true) do
      if_else(eqz(value), do: when_true)
    end

    def enum(cases) do
      Map.new(Enum.with_index(cases), fn {key, index} -> {key, {:i32_const, index}} end)
    end

    def from_4_byte_ascii(<<int::little-size(32)>>), do: int

    defmacro match(value, do: transform) do
      statements =
        for {:->, _, [input, target]} <- transform do
          case input do
            # _ ->
            # like an else clause
            [{:_, _, _}] ->
              target

            [match] ->
              quote do
                %ComponentsGuide.WasmBuilder.IfElse{
                  condition: I32.eq(unquote(value), unquote(match)),
                  when_true: [unquote(get_block_items(target)), break(:i32_match)]
                }
              end
          end
        end

      catchall = for {:->, _, [[{:_, _, _}], _]} <- transform, do: true

      final_instruction =
        case catchall do
          [] -> :unreachable
          [true] -> []
        end

      quote do
        defblock :i32_match, result: I32 do
          unquote(statements)
          unquote(final_instruction)
        end
      end
    end

    defmacro cond(do: transform) do
      statements =
        for {:->, _, [input, target]} <- transform do
          case input do
            # true ->
            # like an else clause
            [true] ->
              target

            [match] ->
              quote do
                %ComponentsGuide.WasmBuilder.IfElse{
                  condition: unquote(match),
                  when_true: [unquote(get_block_items(target)), break(:i32_map)]
                }
              end
          end
        end

      catchall = for {:->, _, [[true], _]} <- transform, do: true

      final_instruction =
        case catchall do
          [] -> :unreachable
          [true] -> []
        end

      quote do
        defblock :i32_map, result: I32 do
          unquote(statements)
          unquote(final_instruction)
        end
      end
    end

    defmacro attr_writer(global_name) do
      quote do
        func unquote(String.to_atom("#{global_name}="))(new_value(I32)) do
          local_get(:new_value)
          global_set(unquote(global_name))
        end
      end
    end

    defmacro attr_writer(global_name, as: func_name) do
      quote do
        func unquote(func_name)(new_value(I32)) do
          local_get(:new_value)
          global_set(unquote(global_name))
        end
      end
    end

    defp get_block_items(block) do
      case block do
        nil -> nil
        {:__block__, _meta, block_items} -> block_items
        single -> [single]
      end
    end

    defmacro global(list) do
      quote do
        @wasm_global for {key, value} <- unquote(list), do: {key, i32(value)}
      end
    end

    defmacro export_global(list) do
      quote do
        @wasm_exported_mutable_global_types for {key, value} <- unquote(list),
                                                do: {key, i32(value)}
      end
    end

    defmacro export_global(:readonly, list) do
      quote do
        @wasm_global_exported_readonly for {key, value} <- unquote(list), do: {key, i32(value)}
      end
    end

    defmacro global(:export_readonly, list) do
      quote do
        @wasm_global_exported_readonly for {key, value} <- unquote(list), do: {key, i32(value)}
      end
    end
  end

  defmodule U32 do
  end

  defmodule F32 do
    require Ops

    for op <- Ops.f32(1) do
      def unquote(op)(a) do
        {:f32, unquote(op), a}
      end
    end

    for op <- Ops.f32(2) do
      def unquote(op)(a, b) do
        {:f32, unquote(op), {a, b}}
      end
    end
  end

  def module(name, do: body) do
    %ModuleDefinition{name: name, body: body}
  end

  def module(name, body) do
    %ModuleDefinition{name: name, body: body}
  end

  defmodule Constants do
    defstruct offset: 0xFF, items: []

    def new(items) do
      items = Enum.uniq(items)
      %__MODULE__{items: items}
    end

    def to_keylist(%__MODULE__{offset: offset, items: items}) do
      {lookup_table, _} =
        items
        |> Enum.map_reduce(offset, fn string, offset ->
          {{string, offset}, offset + byte_size(string) + 1}
        end)

      lookup_table
    end

    def to_map(%__MODULE__{} = receiver) do
      receiver |> to_keylist() |> Map.new()
    end

    def resolve(constants, {:i32_const_string, _strptr, _string} = value) do
      value
    end

    def resolve(constants, value) do
      {:i32_const_string, Map.fetch!(constants, value), value}
    end
  end

  def do_module_body(block, options, env_module) do
    # TODO split into readonly_globals and mutable_globals?
    internal_global_types = Keyword.get(options, :globals, [])
    # TODO rename to export_readonly_globals?
    exported_global_types = Keyword.get(options, :exported_globals, [])
    exported_mutable_global_types = Keyword.get(options, :exported_mutable_globals, [])

    internal_global_types =
      internal_global_types ++
        List.flatten(List.wrap(Module.get_attribute(env_module, :wasm_global)))

    # dbg(env_module)
    # dbg(Module.get_attribute(env_module, :wasm_global))

    globals =
      (internal_global_types ++ exported_global_types ++ exported_mutable_global_types)
      |> Keyword.new(fn {key, _} -> {key, nil} end)
      |> Map.new()

    block_items =
      case block do
        {:__block__, _meta, block_items} -> block_items
        single -> List.wrap(single)
      end

    # block_items = Macro.expand(block_items, env)
    # block_items = block_items

    {block_items, constants} =
      Macro.prewalk(block_items, [], fn
        {:=, _meta1, [{global, _meta2, nil}, input]}, constants
        when is_atom(global) and is_map_key(globals, global) ->
          {[input, global_set(global)], constants}

        {atom, meta, nil}, constants when is_atom(atom) and is_map_key(globals, atom) ->
          {{:global_get, meta, [atom]}, constants}

        {:const, _, [str]}, constants when is_binary(str) ->
          {quote(do: data_for_constant(unquote(str))), [str | constants]}

        {:sigil_S, _, [{:<<>>, _, [str]}, _]}, constants ->
          {
            quote(do: data_for_constant(unquote(str))),
            [str | constants]
          }

        {:sigil_s, _, [{:<<>>, _, [str]}, _]}, constants ->
          {
            quote(do: data_for_constant(unquote(str))),
            [str | constants]
          }

        # {quote(do: data_for_constant(unquote(str))), [str | constants]}

        other, constants ->
          {other, constants}
      end)

    constants = Enum.reverse(constants)

    block_items =
      case constants do
        [] -> block_items
        _ -> [quote(do: Constants.new(unquote(constants))) | block_items]
      end

    %{
      body: block_items,
      constants: constants
    }
  end

  defmacro do_module_body2(block, options, env_module) do
    result = do_module_body(block, options, env_module)[:body]

    quote do
      unquote(result)
    end
  end

  defmodule BeforeCompile do
    defmacro __before_compile__(_env) do
      quote do
        def __wasm_module__() do
          # import Kernel, except: [if: 2, @: 1]
          # import ComponentsGuide.WasmBuilderUsing2

          ModuleDefinition.new(
            # name: unquote(name),
            name: @wasm_name,
            imports: List.flatten(List.wrap(@wasm_imports)),
            globals:
              List.flatten(List.wrap(@wasm_internal_globals)) ++
                List.flatten(List.wrap(@wasm_global)),
            exported_globals: List.flatten(List.wrap(@wasm_global_exported_readonly)),
            exported_mutable_global_types:
              List.flatten(List.wrap(@wasm_exported_mutable_global_types)),
            memory: Memory.from(@wasm_memory),
            body: List.flatten(@wasm_body)
          )
        end

        def funcp(name),
          do: ComponentsGuide.WasmBuilder.ModuleDefinition.funcp_ref!(__MODULE__, name)

        def to_wat(), do: ComponentsGuide.WasmBuilder.to_wat(__wasm_module__())
      end
    end
  end

  defp define_module(name, options, block, env) do
    options = Macro.expand(options, env)

    imports = Keyword.get(options, :imports, [])

    imports =
      for {first, sub_imports} <- imports do
        for {second, definition} <- sub_imports do
          case definition do
            {:func, _meta, [name, arg1]} ->
              quote do
                %Import{
                  module: unquote(first),
                  name: unquote(second),
                  type: FuncType.imported_func(unquote(name), unquote(arg1), nil)
                }
              end

            _ ->
              quote do
                %Import{module: unquote(first), name: unquote(second), type: unquote(definition)}
              end
          end
        end
      end

    imports = List.flatten(imports)

    # TODO split into readonly_globals and mutable_globals?
    internal_global_types = Keyword.get(options, :globals, [])
    # TODO rename to export_readonly_globals?
    exported_global_types = Keyword.get(options, :exported_globals, [])
    exported_mutable_global_types = Keyword.get(options, :exported_mutable_globals, [])

    globals =
      (internal_global_types ++ exported_global_types ++ exported_mutable_global_types)
      |> Keyword.new(fn {key, _} -> {key, nil} end)
      |> Map.new()

    %{body: block_items, constants: constants} = do_module_body(block, options, env.module)
    Module.put_attribute(env.module, :wasm_constants, constants)

    Module.put_attribute(env.module, :wasm_name, name)

    quote do
      # @before_compile unquote(__MODULE__).BeforeCompile

      @wasm_imports unquote(imports)
      @wasm_internal_globals unquote(internal_global_types)
      @wasm_global_exported_readonly unquote(exported_global_types)
      @wasm_exported_mutable_global_types unquote(exported_mutable_global_types)

      import Kernel, except: [if: 2, @: 1]
      import ComponentsGuide.WasmBuilderUsing
      import ComponentsGuide.WasmBuilderUsing2

      @wasm_body unquote(block_items)
      # @wasm_body do_module_body(unquote(block), unquote(options), unquote(env.module))
      # @wasm_body unquote(do_module_body(block, options, env.module)[:body])

      import Kernel
      import ComponentsGuide.WasmBuilderUsing, only: []
      import ComponentsGuide.WasmBuilderUsing2, only: []
    end
  end

  defmacro data_for_constant(value) do
    quote do
      Constants.new(@wasm_constants)
      |> Constants.to_map()
      |> Constants.resolve(unquote(value))
    end
  end

  defmacro defwasm(options \\ [], do: block) do
    name = __CALLER__.module |> Module.split() |> List.last()

    definition = define_module(name, options, block, __CALLER__)

    quote do
      #       def funcp(name), do: ModuleDefinition.funcp_ref!(__MODULE__, name)
      #
      #       def to_wat(), do: ComponentsGuide.WasmBuilder.to_wat(__wasm_module__())

      # import Kernel
      unquote(definition)

      import Kernel
    end
  end

  defmacro wasm(transform \\ nil, do: block) do
    block =
      case Macro.expand_literals(transform, __ENV__) do
        nil -> block
        U32 -> I32.do_u(block)
      end

    %{body: body, constants: constants} = do_module_body(block, [], __CALLER__.module)
    Module.put_attribute(__CALLER__.module, :wasm_constants, constants)

    quote do
      import Kernel, except: [if: 2, @: 1]
      import ComponentsGuide.WasmBuilderUsing
      import ComponentsGuide.WasmBuilderUsing2

      @wasm_body unquote(body)

      import Kernel
      import ComponentsGuide.WasmBuilderUsing, only: []
      import ComponentsGuide.WasmBuilderUsing2, only: []
    end
  end

  defmacro global(list) do
    quote do
      @wasm_global unquote(list)
    end
  end

  defmacro global(:export_readonly, list) do
    quote do
      @wasm_global_exported_readonly unquote(list)
    end
  end

  defmacro wasm_memory(pages: count) do
    quote do
      @wasm_memory unquote(count)
    end
  end

  def expand_type(type) do
    case Macro.expand_literals(type, __ENV__) do
      I32 -> :i32
      F32 -> :f32
      I32.String -> :i32
      I32.Pointer -> :i32_ptr
      I32.I8.Pointer -> :i32_8_ptr
      # Memory.I32.Pointer -> :i32
      _ -> type
    end
  end

  def func(options) do
    name = Keyword.fetch!(options, :name)
    FuncType.imported_func(name, options[:params], options[:result])
  end

  defmacro func(call, options) when is_list(options) do
    {block, options} = Keyword.pop!(options, :do)
    define_func(call, :public, options, block, __CALLER__)
  end

  # defmacro func(call, options, do: block) when is_list(options) do
  #   define_func(call, :public, options, block, __CALLER__)
  # end

  defmacro func(call, result_type, do: block) do
    define_func(call, :public, [result: result_type], block, __CALLER__)
  end

  defmacro func(call, nil, locals, do: block) when is_list(locals) do
    define_func(call, :public, [locals: locals], block, __CALLER__)
  end

  defmacro func(call, result_type, locals, do: block) when is_list(locals) do
    define_func(call, :public, [result: result_type, locals: locals], block, __CALLER__)
  end

  # TODO: require `globals` option be passed to explicitly list global used.
  # Would be useful for sharing funcp between wasm modules too.
  # Also incentivises making funcp pure by having all inputs be parameters.
  defmacro funcp(call, do: block) do
    define_func(call, :private, [], block, __CALLER__)
  end

  defmacro funcp(call, options, do: block) when is_list(options) do
    define_func(call, :private, options, block, __CALLER__)
  end

  defmacro funcp(call, result_type, do: block) do
    define_func(call, :private, [result: result_type], block, __CALLER__)
  end

  defmacro funcp(call, result_type, locals, do: block) when is_list(locals) do
    define_func(call, :private, [result: result_type, locals: locals], block, __CALLER__)
  end

  defp define_func(call, visibility, options, block, env) do
    call = Macro.expand_once(call, __ENV__)

    {name, args} =
      case Macro.decompose_call(call) do
        :error -> {expand_identifier(call, __ENV__), []}
        other -> other
      end

    name = name

    exported? =
      case visibility do
        :public -> true
        :private -> false
      end

    params =
      case args do
        [args] when is_list(args) ->
          for {name, type} <- args do
            Macro.escape(param(name, expand_type(type)))
          end

        args ->
          for {name, _meta, [type]} <- args do
            Macro.escape(param(name, expand_type(type)))
          end
      end

    arg_types =
      case args do
        [args] when is_list(args) ->
          for {name, type} <- args do
            {name, expand_type(type)}
          end

        args ->
          for {name, _meta, [type]} <- args do
            {name, expand_type(type)}
          end
      end

    result_type = Keyword.get(options, :result, nil) |> expand_type()

    local_types =
      for {key, type} <- Keyword.get(options, :locals, []) do
        {key, expand_type(type)}
      end

    locals = Map.new(arg_types ++ local_types)

    # block = Macro.expand_once(block, __ENV__)

    block_items =
      case block do
        {:__block__, _meta, block_items} -> block_items
        single -> [single]
      end

    block_items = Macro.expand(block_items, env)
    block_items = do_snippet(locals, block_items)

    quote do
      # List.flatten([
      #   unquote(Macro.escape(data_els)),
      %Func{
        name: unquote(name),
        params: unquote(params),
        result: result(unquote(result_type)),
        local_types: unquote(local_types),
        body: unquote(block_items),
        exported?: unquote(exported?)
      }

      # ])
    end
  end

  def do_snippet(locals, block_items) do
    Macro.prewalk(block_items, fn
      {:=, _, [{{:., _, [Access, :get]}, _, [{:memory32_8!, _, nil}, offset]}, value]} ->
        quote do: {:i32, :store8, unquote(offset), unquote(value)}

      {{:., _, [{{:., _, [Access, :get]}, _, [{:memory32_8!, _, nil}, offset]}, :unsigned]}, _, _} ->
        quote do: {:i32, :load8_u, unquote(offset)}

      {:=, _, [{{:., _, [Access, :get]}, _, [{:memory32!, _, nil}, offset]}, value]} ->
        quote do: {:i32, :store, unquote(offset), unquote(value)}

      {{:., _, [Access, :get]}, _, [{:memory32!, _, nil}, offset]} ->
        quote do: {:i32, :load, unquote(offset)}

      # local[byte_at!: offset] = value
      {:=, _meta,
       [
         {{:., _, [Access, :get]}, _,
          [
            {local, _, nil},
            [
              byte_at!: offset
            ]
          ]},
         value
       ]}
      when is_atom(local) and is_map_key(locals, local) ->
        # TODO: add exception for when this isn’t the matching type.
        :i32_8_ptr = locals[local]

        quote do:
                {:i32, :store8, I32.add(local_get(unquote(local)), unquote(offset)),
                 unquote(value)}

      {:=, _, [{local, _, nil}, input]}
      when is_atom(local) and is_map_key(locals, local) ->
        [input, quote(do: {:local_set, unquote(local)})]

      {atom, meta, nil} when is_atom(atom) and is_map_key(locals, atom) ->
        {:local_get, meta, [atom]}

      # @some_global = input
      {:=, _, [{:@, _, [{global, _, nil}]}, input]} = term when is_atom(global) ->
        [input, global_set(global)]

      # @some_global
      #       node = {:@, meta, [{global, _, nil}]} when is_atom(global) ->
      #         if global == :weekdays_i32 do
      #           dbg(meta)
      #           dbg(node)
      #         end
      #
      #         {:global_get, meta, [global]}

      {:=, _, [{:_, _, nil}, value]} ->
        quote do: [unquote(value), :drop]

      other ->
        other
    end)
  end

  defmacro snippet(locals \\ [], do: block) do
    block_items =
      case block do
        {:__block__, _meta, items} -> items
        single -> [single]
      end

    locals = Map.new(locals)
    # do_snippet(locals, block_items)

    quote do
      import Kernel, except: [if: 2, @: 1]
      import ComponentsGuide.WasmBuilderUsing
      import ComponentsGuide.WasmBuilderUsing2

      unquote(do_snippet(locals, block_items))
    end
  end

  def memory(name \\ nil, min) do
    %Memory{name: name, min: min}
  end

  def pack_strings_nul_terminated(start_offset, strings_record) do
    {lookup_table, _} =
      Enum.map_reduce(strings_record, start_offset, fn {key, string}, offset ->
        {{key, %{offset: offset, string: string}}, offset + byte_size(string) + 1}
      end)

    Map.new(lookup_table)
  end

  def data(offset, value) do
    %Data{offset: offset, value: value, nul_terminated: false}
  end

  def data_nul_terminated(offset, value) do
    %Data{offset: offset, value: value, nul_terminated: true}
  end

  def data_nul_terminated(packed_map) when is_map(packed_map) do
    for {_key, %{offset: offset, string: string}} <- packed_map do
      data_nul_terminated(offset, string)
    end
  end

  # defmacro data_nul_terminated(offset, key, values) do
  #   %Data{offset: offset, key: key, values: values, nul_terminated: true}
  # end

  def wasm_import(module, name, type) do
    %Import{module: module, name: name, type: type}
  end

  # def global(name, type, initial_value) do
  #   %Global{name: name, type: type, initial_value: initial_value, exported: false}
  # end

  @primitive_types [:i32, :f32, :i32_ptr, :i32_8_ptr]

  def param(name, type) when type in @primitive_types do
    %Param{name: name, type: type}
  end

  def export(name) do
    {:export, name}
  end

  def result(type) when type in @primitive_types, do: {:result, type}
  def result(nil), do: nil

  # TODO: unused
  def i32_const(value), do: {:i32_const, value}
  def i32_boolean(0), do: {:i32_const, 0}
  def i32_boolean(1), do: {:i32_const, 1}
  def i32(op) when op in Ops.i32(:all), do: {:i32, op}
  def i32(n) when is_integer(n), do: {:i32_const, n}

  def push(tuple)
      when is_tuple(tuple) and elem(tuple, 0) in [:i32, :i32_const, :local_get, :global_get],
      do: tuple

  def push(n) when is_integer(n), do: {:i32_const, n}

  defmacro push(value, do: block) do
    quote do
      [
        unquote(value),
        unquote(get_block_items(block)),
        :pop
      ]
    end
  end

  def global_get(identifier), do: {:global_get, identifier}
  def global_set(identifier), do: {:global_set, identifier}

  def local(identifier, type), do: {:local, identifier, type}
  def local_get(identifier), do: {:local_get, identifier}
  def local_set(identifier), do: {:local_set, identifier}
  def local_tee(identifier), do: {:local_tee, identifier}
  def local_tee(identifier, value), do: [value, {:local_tee, identifier}]

  defmacro if_(condition, do: when_true, else: when_false) do
    quote do
      IfElse.detecting_result_type(
        unquote(condition),
        unquote(get_block_items(when_true)),
        unquote(get_block_items(when_false))
      )
    end
  end

  def get_block_items(block) do
    case block do
      nil -> nil
      {:__block__, _meta, block_items} -> block_items
      single -> [single]
    end
  end

  def call(f), do: {:call, f, []}
  def call(f, a), do: {:call, f, [a]}
  def call(f, a, b), do: {:call, f, [a, b]}
  def call(f, a, b, c), do: {:call, f, [a, b, c]}

  defp expand_identifier(identifier, env) do
    identifier = Macro.expand_once(identifier, env) |> Kernel.to_string()

    case identifier do
      "Elixir." <> _rest = string ->
        string |> Module.split() |> Enum.join(".")

      other ->
        other
    end
  end

  defmacro loop(identifier, options \\ [], do: block) do
    identifier = expand_identifier(identifier, __CALLER__)
    result_type = Keyword.get(options, :result, nil) |> expand_type()

    block_items = get_block_items(block)

    block_items =
      Macro.prewalk(block_items, fn
        {{:., _, [{:__aliases__, _, [identifier]}, :continue]}, _, []} ->
          # quote do: br(unquote(identifier))
          quote do: {:br, unquote(identifier)}

        {{:., _, [{:__aliases__, _, [identifier]}, :continue]}, _, [[if: condition]]} ->
          # quote do: br(unquote(identifier))
          quote do: {:br_if, unquote(identifier), unquote(condition)}

        other ->
          other
      end)

    # quote bind_quoted: [identifier: identifier] do
    quote do
      %Loop{
        identifier: unquote(identifier),
        result: unquote(result_type),
        body: unquote(block_items)
      }
    end
  end

  defmacro defblock(identifier, options \\ [], do: block) do
    identifier = expand_identifier(identifier, __CALLER__)
    result_type = Keyword.get(options, :result, nil) |> expand_type()

    block_items = get_block_items(block)

    quote do
      %Block{
        identifier: unquote(identifier),
        result: unquote(result_type),
        body: unquote(block_items)
      }
    end
  end

  # import Kernel

  defmacro inline(do: block) do
    get_block_items(block)
  end

  defmacro inline({:for, meta, [for_arg]}, do: block) do
    # import Kernel
    {:for, meta, [for_arg, [do: get_block_items(block)]]}
    # {:for, meta, [for_arg, [do: quote do: inline(do: unquote(block))]]}
  end

  def const(value) do
    {:const_string, value}
    # mod = __CALLER__.module
    # mod = __ENV__.module

    # quote do
    #   var!(offset) = Module.get_attribute(unquote(mod), :data_offset, 0x4)
    #   var!(new_offset) = byte_size(unquote(value)) + 1
    #   Module.put_attribute(unquote(mod), :data_offset, var!(new_offset))
    #   %Data{offset: var!(offset), value: unquote(value), nul_terminated: true}
    # end
  end

  def const_set_insert(set_name, string) when is_atom(set_name) and is_binary(string) do
    :todo
  end

  # TODO: add a comptime keyword like Zig: https://kristoff.it/blog/what-is-zig-comptime/

  # For blocks
  def break(identifier), do: {:br, expand_identifier(identifier, __ENV__)}

  def break(identifier, if: condition),
    do: {:br_if, expand_identifier(identifier, __ENV__), condition}

  def return(), do: :return
  def return(value), do: {:return, value}

  def nop(), do: :nop

  def drop(), do: :drop
  def drop(expression), do: [expression, :drop]

  def unreachable!(), do: :unreachable

  def assert!(condition) do
    %IfElse{
      result: nil,
      condition: condition,
      when_true: nop(),
      when_false: unreachable!()
    }
  end

  def raw_wat(source), do: {:raw_wat, String.trim(source)}
  def sigil_A(source, _modifiers), do: {:raw_wat, String.trim(source)}

  ####

  # TODO: make this a separate function to the underlying say do_wat()
  def to_wat(term) when is_atom(term),
    do: do_wat(term.__wasm_module__(), "") |> IO.chardata_to_string()

  def to_wat(term), do: do_wat(term, "") |> IO.chardata_to_string()

  def do_wat(term), do: do_wat(term, "")

  def do_wat(term, indent)

  def do_wat(list, indent) when is_list(list) do
    Enum.map(list, &do_wat(&1, indent)) |> Enum.intersperse("\n")
  end

  def do_wat(
        %ModuleDefinition{
          name: name,
          imports: imports,
          exported_globals: exported_globals,
          exported_mutable_global_types: exported_mutable_global_types,
          memory: memory,
          globals: globals,
          body: body
        },
        indent
      ) do
    [
      [indent, "(module $#{name}", "\n"],
      [for(import_def <- imports, do: [do_wat(import_def, "  " <> indent), "\n"])],
      case memory do
        nil ->
          []

        list when is_list(list) ->
          min = Enum.sum(list)

          case min do
            0 ->
              []

            int ->
              [
                ~S{(memory (export "memory")},
                [" ", to_string(int)],
                ~S{)}
              ]
          end

        %Memory{min: min} ->
          [
            ~S{(memory (export "memory")},
            case min do
              nil -> []
              int -> [" ", to_string(int)]
            end,
            ~S{)}
          ]
      end,
      for(
        {name, {:i32_const, initial_value}} <- exported_globals,
        # TODO: handle more than just (mut i32), e.g. non-mut or f64
        do: [
          "  " <> indent,
          ~s[(global $#{name} (export "#{name}") i32 (i32.const #{initial_value}))],
          "\n"
        ]
      ),
      for(
        {name, {:i32_const, initial_value}} <- exported_mutable_global_types,
        # TODO: handle more than just (mut i32), e.g. non-mut or f64
        do: [
          "  " <> indent,
          # ~s[(export "#{name}" (global $#{name} i32 (i32.const #{initial_value})))],
          # ~s[(global $#{name} i32 (i32.const #{initial_value}))],
          ~s[(global $#{name} (export "#{name}") (mut i32) (i32.const #{initial_value}))],
          "\n"
        ]
      ),
      for(
        {name, {:i32_const, initial_value}} <- globals,
        # TODO: handle more than just (mut i32), e.g. non-mut or f64
        do: ["  " <> indent, "(global $#{name} (mut i32) (i32.const #{initial_value}))", "\n"]
      ),
      case body do
        [] ->
          ""

        body ->
          [indent, do_wat(body, "  " <> indent), "\n"]
      end,
      [indent, ")", "\n"]
    ]
  end

  def do_wat(%Import{module: nil, name: name, type: type}, indent) do
    ~s[#{indent}(import "#{name}" #{do_wat(type)})]
  end

  def do_wat(%Import{module: module, name: name, type: type}, indent) do
    ~s[#{indent}(import "#{module}" "#{name}" #{do_wat(type)})]
  end

  def do_wat(%Memory{name: nil, min: min}, indent) do
    ~s[#{indent}(memory #{min})]
  end

  def do_wat(%Memory{name: name, min: min}, indent) do
    ~s"#{indent}(memory #{do_wat(name)} #{min})"
  end

  def do_wat(%FuncType{name: name, param_types: :i32, result_type: result_type}, indent) do
    ~s[#{indent}(func $#{name} (param i32) #{do_wat(result_type)})]
  end

  def do_wat(%Data{offset: offset, value: value, nul_terminated: nul_terminated}, indent) do
    [
      indent,
      "(data (i32.const ",
      to_string(offset),
      ") ",
      ?",
      value |> String.replace(~S["], ~S[\"]) |> String.replace("\n", ~S"\n"),
      if(nul_terminated, do: ~S"\00", else: []),
      ?",
      ")"
    ]
  end

  def do_wat(%Constants{} = constants, indent) do
    # dbg(Constants.to_keylist(constants))
    for {string, offset} <- Constants.to_keylist(constants) do
      [
        indent,
        "(data (i32.const ",
        to_string(offset),
        ") ",
        ?",
        string |> String.replace(~S["], ~S[\"]) |> String.replace("\n", ~S"\n"),
        ?",
        ")"
      ]
    end
    |> Enum.intersperse("\n")
  end

  def do_wat(
        %Global{name: name, type: type, initial_value: initial_value, exported: exported},
        indent
      ) do
    # (global $count (mut i32) (i32.const 0))
    [
      indent,
      "(global ",
      case exported do
        false -> [?$, to_string(name)]
        true -> ["(export ", to_string(name), ?)]
      end,
      " (mut ",
      type,
      ") (i32.const ",
      to_string(initial_value),
      "))"
    ]
  end

  def do_wat(
        %Func{
          name: name,
          params: params,
          result: result,
          local_types: local_types,
          body: body,
          exported?: exported?
        },
        indent
      ) do
    [
      [
        indent,
        case exported? do
          false -> ~s[(func $#{name} ]
          true -> ~s[(func $#{name} (export "#{name}") ]
        end,
        Enum.intersperse(
          for(param <- params, do: do_wat(param)) ++ if(result, do: [do_wat(result)], else: []),
          " "
        ),
        "\n"
      ],
      for({id, type} <- local_types, do: ["  " <> indent, "(local $#{id} #{type})", "\n"]),
      do_wat(body, "  " <> indent),
      "\n",
      [indent, ")"]
    ]
  end

  def do_wat(%Param{name: name, type: type}, indent) do
    [
      indent,
      "(param $",
      to_string(name),
      " ",
      case type do
        type when type in [:i32, :i32_ptr, :i32_8_ptr] -> "i32"
        :f32 -> "f32"
      end,
      ?)
    ]
  end

  def do_wat(
        %IfElse{
          result: result,
          condition: condition,
          when_true: when_true,
          when_false: when_false
        },
        indent
      )
      when not is_nil(condition) do
    [
      [
        indent,
        "(if ",
        if(result, do: ["(result ", to_string(expand_type(result)), ") "], else: ""),
        do_wat(condition, ""),
        ?\n
      ],
      ["  ", indent, "(then", ?\n],
      [do_wat(when_true, "    " <> indent), ?\n],
      ["  ", indent, ")", ?\n],
      if when_false do
        [
          ["  ", indent, "(else", ?\n],
          [do_wat(when_false, "    " <> indent), ?\n],
          ["  ", indent, ")", ?\n]
        ]
      else
        []
      end,
      [indent, ")"]
    ]
  end

  # TODO: remove
  def do_wat({:if, condition, when_true, when_false}, indent) do
    [
      [indent, "(if ", do_wat(condition, ""), ?\n],
      ["  ", indent, "(then", ?\n],
      ["    ", indent, do_wat(when_true, ""), ?\n],
      ["  ", indent, ")", ?\n],
      if when_false do
        [
          ["  ", indent, "(else", ?\n],
          ["    ", indent, do_wat(when_false, ""), ?\n],
          ["  ", indent, ")", ?\n]
        ]
      else
        []
      end,
      [indent, ")"]
    ]
  end

  def do_wat(
        %Loop{identifier: identifier, result: result, body: body},
        indent
      ) do
    [
      [
        indent,
        "(loop $",
        to_string(identifier),
        if(result, do: " (result #{result})", else: []),
        "\n"
      ],
      do_wat(body, "  " <> indent),
      "\n",
      [indent, ")"]
    ]
  end

  def do_wat(
        %Block{identifier: identifier, result: result, body: body},
        indent
      ) do
    [
      [
        indent,
        "(block $",
        to_string(identifier),
        if(result, do: " (result #{result})", else: []),
        "\n"
      ],
      do_wat(body, "  " <> indent),
      "\n",
      [indent, ")"]
    ]
  end

  def do_wat(:nop, indent), do: [indent, "nop"]
  def do_wat(:pop, indent), do: []
  def do_wat(:drop, indent), do: [indent, "drop"]

  def do_wat({:export, name}, _indent), do: "(export \"#{name}\")"
  def do_wat({:result, value}, _indent), do: "(result #{value})"
  def do_wat({:i32_const, value}, indent), do: "#{indent}(i32.const #{value})"
  def do_wat({:i32_const_string, value, _string}, indent), do: "#{indent}(i32.const #{value})"
  def do_wat({:global_get, identifier}, indent), do: "#{indent}(global.get $#{identifier})"
  def do_wat({:global_set, identifier}, indent), do: "#{indent}(global.set $#{identifier})"
  def do_wat({:local, identifier, type}, indent), do: "#{indent}(local $#{identifier} #{type})"
  def do_wat({:local_get, identifier}, indent), do: "#{indent}(local.get $#{identifier})"
  def do_wat({:local_set, identifier}, indent), do: "#{indent}(local.set $#{identifier})"
  def do_wat({:local_tee, identifier}, indent), do: "#{indent}(local.tee $#{identifier})"
  def do_wat(value, indent) when is_integer(value), do: "#{indent}(i32.const #{value})"
  def do_wat(value, indent) when is_float(value), do: "#{indent}(f32.const #{value})"
  def do_wat({:i32, op}, indent) when op in Ops.i32(:all), do: "#{indent}(i32.#{op})"

  def do_wat({:i32, op, offset}, indent) when op in Ops.i32(:load) or op in Ops.i32(:store) do
    [indent, "(i32.", to_string(op), " ", do_wat(offset), ?)]
  end

  def do_wat({:i32, op, offset, value}, indent) when op in Ops.i32(:store) do
    [indent, "(i32.", to_string(op), " ", do_wat(offset), " ", do_wat(value), ?)]
  end

  def do_wat({:i32, op, a}, indent) when op in Ops.i32(1) do
    [indent, "(i32.", to_string(op), " ", do_wat(a), ?)]
  end

  def do_wat({:i32, op, {a, b}}, indent) when op in Ops.i32(2) do
    [indent, "(i32.", to_string(op), " ", do_wat(a), " ", do_wat(b), ?)]
  end

  def do_wat({:f32, op, a}, indent) when op in Ops.f32(1) do
    [indent, "(f32.", to_string(op), " ", do_wat(a), ?)]
  end

  def do_wat({:f32, op, {a, b}}, indent) when op in Ops.f32(2) do
    [indent, "(f32.", to_string(op), " ", do_wat(a), " ", do_wat(b), ?)]
  end

  def do_wat({:call, f, args}, indent) do
    [
      indent,
      "(call $",
      to_string(f),
      for(arg <- args, do: [" ", do_wat(arg)]),
      ")"
    ]
  end

  def do_wat({:br, identifier}, indent), do: [indent, "br $", to_string(identifier)]

  def do_wat({:br_if, identifier, condition}, indent),
    do: [indent, do_wat(condition), "\n", indent, "br_if $", to_string(identifier)]

  def do_wat({:br_if, identifier}, indent),
    do: [indent, "br_if $", to_string(identifier)]

  def do_wat(:select, indent), do: [indent, "select"]

  def do_wat(:return, indent), do: [indent, "return"]
  def do_wat({:return, value}, indent), do: [indent, "(return ", do_wat(value), ?)]

  def do_wat(:unreachable, indent), do: [indent, "unreachable"]

  # def do_wat({:raw_wat, source}, indent), do: "#{indent}#{source}"
  def do_wat({:raw_wat, source}, indent) do
    lines = String.split(source, "\n")

    Enum.intersperse(
      for line <- lines do
        [indent, line]
      end,
      "\n"
    )
  end
end

defmodule ComponentsGuide.WasmBuilderUsing do
  import Kernel, except: [if: 2]
  import ComponentsGuide.WasmBuilder
  # alias ComponentsGuide.WasmBuilder.{I32}

  defmacro if(condition, [result: result], do: when_true, else: when_false) do
    quote do
      %ComponentsGuide.WasmBuilder.IfElse{
        result: unquote(result),
        condition: unquote(condition),
        when_true: unquote(ComponentsGuide.WasmBuilder.get_block_items(when_true)),
        when_false: unquote(ComponentsGuide.WasmBuilder.get_block_items(when_false))
      }
    end
  end

  defmacro if(condition, result: result, do: when_true, else: when_false) do
    quote do
      %ComponentsGuide.WasmBuilder.IfElse{
        result: unquote(result),
        condition: unquote(condition),
        when_true: unquote(when_true),
        when_false: unquote(when_false)
      }
    end
  end

  defmacro if(condition, do: when_true, else: when_false) do
    quote do
      if_(unquote(condition), do: unquote(when_true), else: unquote(when_false))
    end
  end

  defmacro if(condition, do: when_true) do
    quote do
      if_(unquote(condition), do: unquote(when_true), else: nil)
    end
  end

  # defdelegate if(condition, cases), to: ComponentsGuide.WasmBuilder, as: :if_
end

defmodule ComponentsGuide.WasmBuilderUsing2 do
  import Kernel, except: [if: 2, @: 1]
  import ComponentsGuide.WasmBuilderUsing

  defmacro @{name, meta, args} do
    # IO.inspect({name, meta, args})

    # dbg(
    #   {__CALLER__.module, name, Module.attributes_in(__CALLER__.module),
    #    Module.has_attribute?(__CALLER__.module, name)}
    # )

    Kernel.if Module.has_attribute?(__CALLER__.module, name) ||
                String.starts_with?(to_string(name), "_") do
      # Kernel.@({name, meta, args}) || :foo
      term = {name, meta, args}

      quote do
        Kernel.@(unquote(term))
      end

      # nil
    else
      {:global_get, meta, [name]}
    end
  end

  #   defmacro @{name, meta, args} do
  #     IO.inspect({name, meta, args})
  #     # dbg(
  #     #   {__CALLER__.module, name, Module.attributes_in(__CALLER__.module),
  #     #    Module.has_attribute?(__CALLER__.module, name)}
  #     # )
  #
  #     Kernel.if Module.has_attribute?(__CALLER__.module, name) ||
  #                 String.starts_with?(to_string(name), "_") do
  #       # Kernel.@({name, meta, args}) || :foo
  #       Kernel.@(name) || :foo
  #       # nil
  #     else
  #       {:global_get, meta, [name]}
  #     end
  #   end
end
