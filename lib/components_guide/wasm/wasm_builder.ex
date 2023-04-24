# TODO: rename to Orb
defmodule ComponentsGuide.WasmBuilder do
  alias ComponentsGuide.Wasm.Ops
  require Ops

  defmacro __using__(_) do
    quote do
      import ComponentsGuide.WasmBuilder
      alias ComponentsGuide.WasmBuilder.{I32, F32}
    end
  end

  defmodule Param do
    defstruct [:name, :type]
  end

  defmodule Func do
    defstruct [:name, :params, :result, :local_types, :body]
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

  defmodule Module do
    defstruct name: nil, imports: [], exported_globals: [], globals: [], body: []

    def fetch_funcp!(%__MODULE__{body: body}, name) do
      body = List.flatten(body)

      # func = Enum.find(body, &match?(%Func{name: ^name}, &1))
      func =
        Enum.find(body, fn
          %Func{name: ^name} -> true
          _ -> false
        end)

      func || raise KeyError, key: name, term: body
    end
  end

  defmodule Import do
    defstruct [:module, :name, :type]
  end

  defmodule Memory do
    defstruct [:name, :min]
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
    def unquote(:and)(a, b)
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
      def unquote(op)(a, b) do
        {:i32, unquote(op), {a, b}}
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

    def unquote(:or)(a, b, c), do: {:i32, :or, {{:i32, :or, {a, b}}, c}}

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

  @primitive_types [:i32, :f32]

  def module(name, do: body) do
    %Module{name: name, body: body}
  end

  def module(name, body) do
    %Module{name: name, body: body}
  end

  defmodule Constants do
    defstruct offset: 0xff, items: []

    def add_constant(%__MODULE__{} = receiver, value) do
      update_in(receiver.items, &[value | &1])
    end

    def to_keylist(%__MODULE__{offset: offset, items: items}) do
      {lookup_table, _} =
        Enum.map_reduce(items, offset, fn string, offset ->
          {{string, offset}, offset + byte_size(string) + 1}
        end)

        lookup_table
    end

    def to_map(%__MODULE__{} = receiver) do
      receiver |> to_keylist() |> Map.new()
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

    internal_global_types = Keyword.get(options, :globals, [])
    exported_global_types = Keyword.get(options, :exported_globals, [])

    # internal_global_types =
    #   for {name, value} <- internal_global_types do
    #     quote do
    #       {unquote(name), Global.new(unquote(name), :internal, unquote(value))}
    #     end
    #   end

    # exported_global_types =
    #   for {name, value} <- exported_global_types do
    #     {name, Global.new(name, :exported, value)}
    #     # quote do
    #     #   {unquote(name), Global.new(unquote(name), :exported, unquote(value))}
    #     # end
    #   end

    globals =
      (internal_global_types ++ exported_global_types)
      |> Keyword.new(fn {key, _} -> {key, nil} end)
      |> Map.new()

    # block = Macro.expand(block, env)
    block_items =
      case block do
        {:__block__, _meta, block_items} -> block_items
        single -> List.wrap(single)
      end

    # block_items = Macro.expand(block_items, env)
    # block_items = block_items

    {block_items, constants} =
      Macro.prewalk(block_items, %Constants{}, fn
        {:=, _meta1, [{global, _meta2, nil}, input]}, constants
        when is_atom(global) and is_map_key(globals, global) ->
          {[input, global_set(global)], constants}

        {atom, meta, nil}, constants when is_atom(atom) and is_map_key(globals, atom) ->
          {{:global_get, meta, [atom]}, constants}

        {:const, _, [str]}, constants ->
          {(quote do: data_for_constant(unquote(Macro.escape(str)))), Constants.add_constant(constants, Macro.escape(str))}

        other, constants ->
          {other, constants}
      end)

    # block_items = List.flatten(block_items)

    Elixir.Module.put_attribute(env.module, :wasm_constants, constants)

    block_items = case constants.items do
      [] -> block_items
      _ -> [Macro.escape(constants) | block_items]
    end

    quote do
      %Module{
        name: unquote(name),
        imports: unquote(imports),
        globals: unquote(internal_global_types),
        exported_globals: unquote(exported_global_types),
        body: unquote(block_items)
      }
    end
  end

  defmacro defwasm(options \\ [], do: block) do
    name = __CALLER__.module |> Elixir.Module.split() |> List.last()

    # options = Macro.expand(options, __CALLER__)

    # block = quote context: __CALLER__.module, do: unquote(block)
    definition = define_module(name, options, block, __CALLER__)

    quote do
      # Elixir.Module.put_attribute(__MODULE__, :wasm_module, unquote(definition))

      def data_for_constant(value) do
        constants = Constants.to_map(@wasm_constants)
        dbg(@wasm_constants)
        dbg(constants)
        Map.fetch!(constants, value)
        # %Data{offset: 0xff, value: value, nul_terminated: true}
      end

      def __wasm_module__() do
        import Kernel, except: [if: 2]
        import ComponentsGuide.WasmBuilderUsing

        # ComponentsGuide.WasmBuilder.define_module(unquote(name), unquote(options), unquote(block), __ENV__)
        unquote(definition)
      end

      # TODO: what is the best way to pass this value along?
      # def __wasm_module__(), do: @wasm_module

      def __wasm_funcp__(name), do: Module.fetch_funcp!(__wasm_module__(), name)

      def to_wat(), do: ComponentsGuide.WasmBuilder.to_wat(__wasm_module__())

      # import Kernel
    end
  end

  defp expand_type(type) do
    case Macro.expand_literals(type, __ENV__) do
      I32 -> :i32
      F32 -> :f32
      _ -> type
    end
  end

  def func(options) do
    name = Keyword.fetch!(options, :name)
    FuncType.imported_func(name, options[:params], options[:result])
  end

  defmacro func(call, options) do
    {block, options} = Keyword.pop!(options, :do)
    define_func(call, :public, options, block)
  end

  defmacro func(call, options, do: block) do
    define_func(call, :public, options, block)
  end

  # TODO: require `globals` option be passed to explicitly list global used.
  # Would be useful for sharing funcp between wasm modules too.
  # Also incentivises making funcp pure by having all inputs be parameters.
  defmacro funcp(call, options \\ [], do: block) do
    define_func(call, :private, options, block)
  end

  defmacro cpfuncp(call, options) do
    {name, _args} = Macro.decompose_call(call)

    source = Keyword.fetch!(options, :from)
    source = Macro.expand(source, __CALLER__)
    func = source.__wasm_funcp__(name)

    # local_def = Macro.expand_literals(define_func(call, :private, options, nil), __CALLER__)

    # local_def = Macro.expand(define_func(call, :private, options, nil), __CALLER__)
    # local_def = define_func(call, :private, options, nil)
    # IO.inspect(local_def)
    # IO.inspect(name)
    # quote bind_quoted: [name: name] do
    #   case unquote(local_def) do
    #     %{name: ^name} -> unquote(func)
    #     _ -> raise "Function options must match source"
    #   end
    # end

    # case local_def do
    #   %{name: ^name} -> Macro.escape(func)
    #   _ -> raise "Function options must match source"
    # end

    Macro.escape(func)
  end

  defp define_func(call, visibility, options, block) do
    call = Macro.expand_once(call, __ENV__)

    {name, args} =
      case Macro.decompose_call(call) do
        :error -> {expand_identifier(call, __ENV__), []}
        other -> other
      end

    # {name, args} = Macro.decompose_call(call)

    name =
      case visibility do
        :public -> export(name)
        :private -> name
      end

    params =
      for {name, _meta, [type]} <- args do
        Macro.escape(param(name, expand_type(type)))
      end

    arg_types =
      for {name, _meta, [type]} <- args do
        {name, expand_type(type)}
      end

    result_type = Keyword.get(options, :result, nil) |> expand_type()

    local_types =
      for {key, type} <- Keyword.get(options, :locals, []) do
        {key, expand_type(type)}
      end

    locals = Map.new(arg_types ++ local_types)

    block_items =
      case block do
        {:__block__, _meta, block_items} -> block_items
        single -> [single]
      end

    block_items =
      Macro.prewalk(block_items, fn
        {:=, _, [{{:., _, [Access, :get]}, _, [{:memory32_8!, _, nil}, offset]}, value]} ->
          quote do: {:i32, :store8, unquote(offset), unquote(value)}

        {{:., _, [{{:., _, [Access, :get]}, _, [{:memory32_8!, _, nil}, offset]}, :unsigned]}, _,
         _} ->
          quote do: {:i32, :load8_u, unquote(offset)}

        {:=, _, [{{:., _, [Access, :get]}, _, [{:memory32!, _, nil}, offset]}, value]} ->
          quote do: {:i32, :store, unquote(offset), unquote(value)}

        {{:., _, [Access, :get]}, _, [{:memory32!, _, nil}, offset]} ->
          quote do: {:i32, :load, unquote(offset)}

        {:=, _, [{local, _, nil}, input]}
        when is_atom(local) and is_map_key(locals, local) ->
          [input, quote(do: {:local_set, unquote(local)})]

        {atom, meta, nil} when is_atom(atom) and is_map_key(locals, atom) ->
          {:local_get, meta, [atom]}

        other ->
          other
      end)

    # constants = for {:const, _, [str]} when is_binary(str) <- Macro.prewalker(block_items) do
    #   str
    # end
    # {data_els, _} = Enum.map_reduce(constants, 0x4, fn string, offset ->
    #   {data_nul_terminated(offset, string), offset + byte_size(string) + 1}
    # end)

    quote do
      # List.flatten([
      #   unquote(Macro.escape(data_els)),
      %Func{
        name: unquote(name),
        params: unquote(params),
        result: result(unquote(result_type)),
        local_types: unquote(local_types),
        body: unquote(block_items)
      }

      # ])
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
  def i32(op) when op in Ops.i32(:all), do: {:i32, op}
  def i32(n) when is_integer(n), do: {:i32_const, n}

  def push(tuple)
      when is_tuple(tuple) and elem(tuple, 0) in [:i32, :i32_const, :local_get, :global_get],
      do: tuple

  def push(n) when is_integer(n), do: {:i32_const, n}

  def global_get(identifier), do: {:global_get, identifier}
  def global_set(identifier), do: {:global_set, identifier}

  def local(identifier, type), do: {:local, identifier, type}
  def local_get(identifier), do: {:local_get, identifier}
  def local_set(identifier), do: {:local_set, identifier}
  def local_tee(identifier), do: {:local_tee, identifier}

  defmacro if_(condition, do: when_true, else: when_false) do
    quote do
      IfElse.detecting_result_type(
        unquote(condition),
        unquote(get_block_items(when_true)),
        unquote(get_block_items(when_false))
      )
    end
  end

  defp get_block_items(block) do
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
        string |> Elixir.Module.split() |> Enum.join(".")

      other ->
        other
    end
  end

  defmacro defloop(identifier, options \\ [], do: block) do
    identifier = expand_identifier(identifier, __CALLER__)
    result_type = Keyword.get(options, :result, nil) |> expand_type()

    block_items = get_block_items(block)

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

  defmacro inline(do: block) do
    get_block_items(block)
  end

  defmacro inline({:for, meta, [for_arg]}, do: block) do
    {:for, meta, [for_arg, [do: get_block_items(block)]]}
    # {:for, meta, [for_arg, [do: quote do: inline(do: unquote(block))]]}
  end

  def const(value) do
    {:const_string, value}
    # mod = __CALLER__.module
    # mod = __ENV__.module

    # quote do
    #   var!(offset) = Elixir.Module.get_attribute(unquote(mod), :data_offset, 0x4)
    #   var!(new_offset) = byte_size(unquote(value)) + 1
    #   Elixir.Module.put_attribute(unquote(mod), :data_offset, var!(new_offset))
    #   %Data{offset: var!(offset), value: unquote(value), nul_terminated: true}
    # end
  end

  def const_set_insert(set_name, string) when is_atom(set_name) and is_binary(string) do
    :todo
  end

  # TODO: add a comptime keyword like Zig: https://kristoff.it/blog/what-is-zig-comptime/

  def br_if(identifier, condition),
    do: {:br_if, expand_identifier(identifier, __ENV__), condition}

  def br(identifier), do: {:br, expand_identifier(identifier, __ENV__)}

  def br(identifier, if: condition),
    do: {:br_if, expand_identifier(identifier, __ENV__), condition}

  def branch(identifier), do: br(identifier)
  def branch(identifier, options), do: br(identifier, options)

  def break(identifier), do: br(identifier)
  def break(identifier, options), do: br(identifier, options)

  def return(), do: :return
  def return(value), do: {:return, value}

  def raw_wat(source), do: {:raw_wat, String.trim(source)}

  ####

  def to_wat(term) when is_atom(term),
    do: to_wat(term.__wasm_module__(), "") |> IO.chardata_to_string()

  def to_wat(term), do: to_wat(term, "") |> IO.chardata_to_string()

  def to_wat(term, indent)

  def to_wat(list, indent) when is_list(list) do
    Enum.map(list, &to_wat(&1, indent)) |> Enum.intersperse("\n")
  end

  def to_wat(
        %Module{
          name: name,
          imports: imports,
          exported_globals: exported_globals,
          globals: globals,
          body: body
        },
        indent
      ) do
    [
      [indent, "(module $#{name}", "\n"],
      [for(import_def <- imports, do: [to_wat(import_def, "  " <> indent), "\n"])],
      for(
        {name, {:i32_const, initial_value}} <- exported_globals,
        # TODO: handle more than just (mut i32), e.g. non-mut or f64
        do: [
          "  " <> indent,
          # ~s[(export "#{name}" (global $#{name} i32 (i32.const #{initial_value})))],
          # ~s[(global $#{name} i32 (i32.const #{initial_value}))],
          ~s[(global $#{name} (mut i32) (i32.const #{initial_value}))],
          "\n",
          "  " <> indent,
          ~s[(export "#{name}" (global $#{name}))],
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
          [indent, to_wat(body, "  " <> indent), "\n"]
      end,
      [indent, ")", "\n"]
    ]
  end

  def to_wat(%Import{module: nil, name: name, type: type}, indent) do
    ~s[#{indent}(import "#{name}" #{to_wat(type)})]
  end

  def to_wat(%Import{module: module, name: name, type: type}, indent) do
    ~s[#{indent}(import "#{module}" "#{name}" #{to_wat(type)})]
  end

  def to_wat(%Memory{name: nil, min: min}, indent) do
    ~s[#{indent}(memory #{min})]
  end

  def to_wat(%Memory{name: name, min: min}, indent) do
    ~s"#{indent}(memory #{to_wat(name)} #{min})"
  end

  def to_wat(%FuncType{name: name, param_types: :i32, result_type: result_type}, indent) do
    ~s[#{indent}(func $#{name} (param i32) #{to_wat(result_type)})]
  end

  def to_wat(%Data{offset: offset, value: value, nul_terminated: true}, indent) do
    [
      indent,
      "(data (i32.const ",
      to_string(offset),
      ") ",
      ?",
      String.replace(value, ~S["], ~S[\"]),
      ~S"\00",
      ?",
      ")"
    ]
  end

  def to_wat(%Data{offset: offset, value: value, nul_terminated: false}, indent) do
    [
      indent,
      "(data (i32.const ",
      to_string(offset),
      ") ",
      ?",
      String.replace(value, ~S["], ~S[\"]),
      ?",
      ")"
    ]
  end

  def to_wat(%Constants{} = constants, indent) do
    for {string, offset} <- Constants.to_keylist(constants) do
      [
        indent,
        "(data (i32.const ",
        to_string(offset),
        ") ",
        ?",
        String.replace(string, ~S["], ~S[\"]),
        ?",
        ")"
      ]
    end
  end

  def to_wat(
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

  def to_wat(
        %Func{name: name, params: params, result: result, local_types: local_types, body: body},
        indent
      ) do
    [
      [
        indent,
        case name do
          name when is_atom(name) -> ~s[(func $#{name} ]
          {:export, name} -> ~s[(func (export "#{name}") ]
        end,
        Enum.intersperse(
          for(param <- params, do: to_wat(param)) ++ if(result, do: [to_wat(result)], else: []),
          " "
        ),
        "\n"
      ],
      for({id, type} <- local_types, do: ["  " <> indent, "(local $#{id} #{type})", "\n"]),
      to_wat(body, "  " <> indent),
      "\n",
      [indent, ")"]
    ]
  end

  def to_wat(%Param{name: name, type: type}, indent) do
    ~s"#{indent}(param $#{name} #{type})"
  end

  def to_wat(
        %IfElse{
          result: result,
          condition: condition,
          when_true: when_true,
          when_false: when_false
        },
        indent
      ) do
    [
      [
        indent,
        "(if ",
        if(result, do: "(result #{result}) ", else: ""),
        to_wat(condition, ""),
        ?\n
      ],
      ["  ", indent, "(then", ?\n],
      [to_wat(when_true, "    " <> indent), ?\n],
      ["  ", indent, ")", ?\n],
      if when_false do
        [
          ["  ", indent, "(else", ?\n],
          [to_wat(when_false, "    " <> indent), ?\n],
          ["  ", indent, ")", ?\n]
        ]
      else
        []
      end,
      [indent, ")"]
    ]
  end

  # TODO: remove
  def to_wat({:if, condition, when_true, when_false}, indent) do
    [
      [indent, "(if ", to_wat(condition, ""), ?\n],
      ["  ", indent, "(then", ?\n],
      ["    ", indent, to_wat(when_true, ""), ?\n],
      ["  ", indent, ")", ?\n],
      if when_false do
        [
          ["  ", indent, "(else", ?\n],
          ["    ", indent, to_wat(when_false, ""), ?\n],
          ["  ", indent, ")", ?\n]
        ]
      else
        []
      end,
      [indent, ")"]
    ]
  end

  def to_wat(
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
      to_wat(body, "  " <> indent),
      "\n",
      [indent, ")"]
    ]
  end

  def to_wat(
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
      to_wat(body, "  " <> indent),
      "\n",
      [indent, ")"]
    ]
  end

  def to_wat(:nop, indent), do: [indent, "nop"]
  def to_wat({:export, name}, _indent), do: "(export \"#{name}\")"
  def to_wat({:result, value}, _indent), do: "(result #{value})"
  def to_wat({:i32_const, value}, indent), do: "#{indent}(i32.const #{value})"
  def to_wat({:global_get, identifier}, indent), do: "#{indent}(global.get $#{identifier})"
  def to_wat({:global_set, identifier}, indent), do: "#{indent}(global.set $#{identifier})"
  def to_wat({:local, identifier, type}, indent), do: "#{indent}(local $#{identifier} #{type})"
  def to_wat({:local_get, identifier}, indent), do: "#{indent}(local.get $#{identifier})"
  def to_wat({:local_set, identifier}, indent), do: "#{indent}(local.set $#{identifier})"
  def to_wat({:local_tee, identifier}, indent), do: "#{indent}(local.tee $#{identifier})"
  def to_wat(value, indent) when is_integer(value), do: "#{indent}(i32.const #{value})"
  def to_wat(value, indent) when is_float(value), do: "#{indent}(f32.const #{value})"
  def to_wat({:i32, op}, indent) when op in Ops.i32(:all), do: "#{indent}(i32.#{op})"

  def to_wat({:i32, op, offset}, indent) when op in Ops.i32(:load) or op in Ops.i32(:store) do
    [indent, "(i32.", to_string(op), " ", to_wat(offset), ?)]
  end

  def to_wat({:i32, op, offset, value}, indent) when op in Ops.i32(:store) do
    [indent, "(i32.", to_string(op), " ", to_wat(offset), " ", to_wat(value), ?)]
  end

  def to_wat({:i32, op, a}, indent) when op in Ops.i32(1) do
    [indent, "(i32.", to_string(op), " ", to_wat(a), ?)]
  end

  def to_wat({:i32, op, {a, b}}, indent) when op in Ops.i32(2) do
    [indent, "(i32.", to_string(op), " ", to_wat(a), " ", to_wat(b), ?)]
  end

  def to_wat({:f32, op, a}, indent) when op in Ops.f32(1) do
    [indent, "(f32.", to_string(op), " ", to_wat(a), ?)]
  end

  def to_wat({:f32, op, {a, b}}, indent) when op in Ops.f32(2) do
    [indent, "(f32.", to_string(op), " ", to_wat(a), " ", to_wat(b), ?)]
  end

  def to_wat({:call, f, args}, indent) do
    [
      indent,
      "(call $",
      to_string(f),
      for(arg <- args, do: [" ", to_wat(arg)]),
      ")"
    ]
  end

  def to_wat({:br, identifier}, indent), do: [indent, "br $", to_string(identifier)]

  def to_wat({:br_if, identifier, condition}, indent),
    do: [indent, to_wat(condition), "\n", indent, "br_if $", to_string(identifier)]

  def to_wat({:br_if, identifier}, indent),
    do: [indent, "br_if $", to_string(identifier)]

  def to_wat(:return, indent), do: [indent, "return"]
  def to_wat({:return, value}, indent), do: [indent, "(return ", to_wat(value), ?)]

  # def to_wat({:raw_wat, source}, indent), do: "#{indent}#{source}"
  def to_wat({:raw_wat, source}, indent) do
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
