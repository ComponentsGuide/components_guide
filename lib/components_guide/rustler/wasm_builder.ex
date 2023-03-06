defmodule ComponentsGuide.Rustler.WasmBuilder do
  defmacro __using__(_) do
    quote do
      import ComponentsGuide.Rustler.WasmBuilder
      alias ComponentsGuide.Rustler.WasmBuilder.{I32}
    end
  end

  defmodule Module do
    defstruct name: nil, imports: [], globals: [], body: []
  end

  defmodule Import do
    defstruct [:module, :name, :type]
  end

  defmodule Memory do
    defstruct [:name, :min]
  end

  defmodule Data do
    defstruct [:offset, :value]
  end

  defmodule Global do
    defstruct [:name, :type, :initial_value]
  end

  defmodule Func do
    defstruct [:name, :params, :result, :local_types, :body]
  end

  defmodule Param do
    defstruct [:name, :type]
  end

  # See: https://webassembly.github.io/spec/core/syntax/instructions.html#numeric-instructions
  @i_unary_ops ~w(clz ctz popcnt)a
  @i_binary_ops ~w(add sub mul div_u div_s rem_u rem_s and or xor shl shr_u shr_s rotl rotr)a
  @i_test_ops ~w(eqz)a
  @i_relative_ops ~w(eq ne lt_u lt_s gt_u gt_s le_u le_s ge_u ge_s)a
  @i32_ops_1 @i_unary_ops ++ @i_test_ops
  @i32_ops_2 @i_binary_ops ++ @i_relative_ops
  @i32_ops_all @i32_ops_1 ++ @i32_ops_2

  defmodule I32 do
    def add(first, second)
    def sub(first, second)
    def mul(first, second)
    def div_u(first, second)
    def div_s(first, second)
    def rem_u(first, second)
    def rem_s(first, second)
    def unquote(:and)(first, second)
    def unquote(:or)(first, second)
    def xor(first, second)
    def shl(first, second)
    def shr_u(first, second)
    def shr_s(first, second)
    def rotl(first, second)
    def rotr(first, second)

    for op <- ~w(add sub mul div_u div_s rem_u rem_s and or xor shl shr_u shr_s rotl rotr)a do
      def unquote(op)(first, second) do
        {:i32, unquote(op), {first, second}}
      end
    end

    def unquote(:lt_s)(first, second) do
      # [first, second, {:i32, :lt_s}]
      {:i32, :lt_s, {first, second}}
    end

    def unquote(:gt_s)(first, second) do
      # [first, second, {:i32, :gt_s}]
      {:i32, :gt_s, {first, second}}
    end

    def unquote(:eqz)() do
      {:i32, :eqz}
    end
  end

  @primitive_types [:i32, :f32]

  def module(name, do: body) do
    %Module{name: name, body: body}
  end

  def module(name, body) do
    %Module{name: name, body: body}
  end

  # defmacro defwasmmodule(call, do: block) when is_list(block) do
  #   define_module(call, block)
  # end

  defmacro defwasmmodule(call, do: block) do
    define_module(Macro.to_string(call), [], block)
  end

  defp define_module(name, options, block) do
    imports = Keyword.get(options, :imports, [])

    imports =
      for {first, sub_imports} <- imports do
        for {second, definition} <- sub_imports do
          quote do
            %Import{module: unquote(first), name: unquote(second), type: unquote(definition)}
          end
        end
      end

    global_types = Keyword.get(options, :globals, [])

    block_items =
      case block do
        {:__block__, [], block_items} -> block_items
        single -> [single]
      end

    block_items =
      Macro.prewalk(block_items, fn
        {:func, meta, [call, options, [do: block]]} ->
          {:func, meta, [call, Keyword.put(options, :globals, global_types), [do: block]]}

        {:func, meta, [call, [do: block]]} ->
          {:func, meta, [call, [globals: global_types], [do: block]]}

        other ->
          other
      end)

    quote do
      %Module{
        name: unquote(name),
        imports: unquote(imports),
        globals: unquote(global_types),
        body: unquote(block_items)
      }
    end
  end

  defmacro defwasm(options \\ [], do: block) do
    name = __CALLER__.module |> Elixir.Module.split() |> List.last()

    definition = define_module(name, options, block)

    quote do
      Elixir.Module.put_attribute(__MODULE__, :wasm_module, unquote(definition))

      def __wasm_module__(), do: unquote(definition)
    end
  end

  defmacro func(call, options \\ [], do: block) do
    define_func(call, :public, options, block)
  end

  defmacro funcp(call, options \\ [], do: block) do
    define_func(call, :private, options, block)
  end

  defp define_func(call, visibility, options, block) do
    {name, args} = Macro.decompose_call(call)

    name =
      case visibility do
        :public -> export(name)
        :private -> name
      end

    params =
      for {name, _meta, [type]} <- args do
        Macro.escape(param(name, type))
      end

    arg_types =
      for {name, _meta, [type]} <- args do
        {name, type}
      end

    result_type = Keyword.get(options, :result, nil)
    local_types = Keyword.get(options, :locals, [])
    global_types = Keyword.get(options, :globals, [])

    locals = Map.new(arg_types ++ local_types)
    globals = Map.new(global_types)

    block_items =
      case block do
        {:__block__, _meta, block_items} ->
          for block_item <- block_items do
            magic_func_item(block_item, locals, globals)
          end

        single ->
          [magic_func_item(single, locals, globals)]
      end

    quote do
      %Func{
        name: unquote(name),
        params: unquote(params),
        result: unquote(result_type) && result(unquote(result_type)),
        local_types: unquote(local_types),
        body: unquote(block_items)
      }
    end
  end

  # TODO: remove
  defp magic_func_item({f, meta, [{atom, _, nil}]}, locals, _globals)
       when f in [:local_get] and is_atom(atom) and is_map_key(locals, atom) do
    {f, meta, [atom]}
  end

  defp magic_func_item(
         {{:., meta1, [{:__aliases__, meta2, [:I32]}, op]}, meta3, args},
         locals,
         globals
       )
       when op in @i32_ops_2 do
    {{:., meta1, [{:__aliases__, meta2, [:I32]}, op]}, meta3,
     Enum.map(args, &magic_func_arg(&1, locals, globals))}
  end

  defp magic_func_item({:=, _meta1, [{global, _meta2, nil}, input]}, locals, globals)
       when is_map_key(globals, global) do
    [magic_func_item(input, locals, globals), global_set(global)]
  end

  defp magic_func_item({:=, _meta1, [{local, _meta2, nil}, input]}, locals, globals)
       when is_map_key(locals, local) do
    [magic_func_item(input, locals, globals), local_set(local)]
  end

  defp magic_func_item(item, _locals, _globals) do
    item
  end

  defp magic_func_arg({atom, meta, nil}, _locals, globals)
       when is_atom(atom) and is_map_key(globals, atom) do
    {:global_get, meta, [atom]}
  end

  defp magic_func_arg({atom, meta, nil}, locals, _globals)
       when is_atom(atom) and is_map_key(locals, atom) do
    {:local_get, meta, [atom]}
  end

  defp magic_func_arg(item, _locals, _globals) do
    item
  end

  def memory(name \\ nil, min) do
    %Memory{name: name, min: min}
  end

  def data(offset, value) do
    %Data{offset: offset, value: value}
  end

  def wasm_import(module, name, type) do
    %Import{module: module, name: name, type: type}
  end

  def global(name, type, initial_value) do
    %Global{name: name, type: type, initial_value: initial_value}
  end

  def param(name, type) when type in @primitive_types do
    %Param{name: name, type: type}
  end

  def export(name) do
    {:export, name}
  end

  def result(type) when type in @primitive_types do
    {:result, type}
  end

  def i32_const(value), do: {:i32_const, value}
  def i32(op) when op in @i32_ops_all, do: {:i32, op}
  def i32(op) when is_number(op), do: {:i32_const, op}

  def global_get(identifier), do: {:global_get, identifier}
  def global_set(identifier), do: {:global_set, identifier}

  def local(identifier, type), do: {:local, identifier, type}
  def local_get(identifier), do: {:local_get, identifier}
  def local_set(identifier), do: {:local_set, identifier}

  def to_wat(term) when is_atom(term),
    do: to_wat(term.__wasm_module__(), "") |> IO.chardata_to_string()

  def to_wat(term), do: to_wat(term, "") |> IO.chardata_to_string()

  def to_wat(term, indent)

  def to_wat(list, indent) when is_list(list) do
    Enum.map(list, &to_wat(&1, indent)) |> Enum.intersperse("\n")
  end

  def to_wat(%Module{name: name, imports: imports, globals: globals, body: body}, indent) do
    [
      [indent, "(module $#{name}", "\n"],
      [for(import_def <- imports, do: [to_wat(import_def, "  " <> indent), "\n"])],
      for(
        {name, {:i32_const, initial_value}} <- globals,
        do: ["  " <> indent, "(global $#{name} (mut i32) (i32.const #{initial_value}))", "\n"]
      ),
      [indent, to_wat(body, "  " <> indent), "\n"],
      [indent, ")", "\n"]
    ]
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

  def to_wat(%Data{offset: offset, value: value}, indent) do
    ~s[#{indent}(data (i32.const #{offset}) "#{value}")]
  end

  def to_wat(%Global{name: name, type: type, initial_value: initial_value}, indent) do
    # (global $count (mut i32) (i32.const 0))
    ~s[#{indent}(global $#{name} (mut #{type}) (i32.const #{initial_value}))]
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

  def to_wat({:export, name}, _indent), do: "(export \"#{name}\")"
  def to_wat({:result, value}, _indent), do: "(result #{value})"
  def to_wat({:i32_const, value}, indent), do: "#{indent}i32.const #{value}"
  def to_wat({:global_get, identifier}, indent), do: "#{indent}global.get $#{identifier}"
  def to_wat({:global_set, identifier}, indent), do: "#{indent}global.set $#{identifier}"
  def to_wat({:local, identifier, type}, indent), do: "#{indent}(local $#{identifier} #{type})"
  def to_wat({:local_get, identifier}, indent), do: "#{indent}local.get $#{identifier}"
  def to_wat({:local_set, identifier}, indent), do: "#{indent}local.set $#{identifier}"
  def to_wat(value, indent) when is_integer(value), do: "#{indent}i32.const #{value}"
  def to_wat(value, indent) when is_float(value), do: "#{indent}f32.const #{value}"
  def to_wat({:i32, op}, indent) when op in @i32_ops_all, do: "#{indent}i32.#{op}"

  def to_wat({:i32, op, {a, b}}, indent) when op in @i32_ops_2,
    do: "#{indent}(i32.#{op} (#{to_wat(a)}) (#{to_wat(b)}))"
end
