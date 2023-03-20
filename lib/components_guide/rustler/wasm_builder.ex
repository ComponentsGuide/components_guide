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
    defstruct [:offset, :value, :nil_terminated]
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

  defmodule IfElse do
    defstruct [:result, :condition, :when_true, :when_false]
  end

  defmodule Loop do
    defstruct [:identifier, :result, :body]
  end

  defmodule Block do
    defstruct [:identifier, :result, :body]
  end

  # See: https://webassembly.github.io/spec/core/syntax/instructions.html#numeric-instructions
  @i_unary_ops ~w(clz ctz popcnt)a
  @i_binary_ops ~w(add sub mul div_u div_s rem_u rem_s and or xor shl shr_u shr_s rotl rotr)a
  @i_test_ops ~w(eqz)a
  @i_relative_ops ~w(eq ne lt_u lt_s gt_u gt_s le_u le_s ge_u ge_s)a
  @i_load_ops ~w(load load8_u)a
  @i_store_ops ~w(store)a
  @i32_ops_1 @i_unary_ops ++ @i_test_ops
  @i32_ops_2 @i_binary_ops ++ @i_relative_ops
  @i32_ops_all @i32_ops_1 ++ @i32_ops_2 ++ @i_load_ops ++ @i_store_ops

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

    def lt_s(first, second) do
      # [first, second, {:i32, :lt_s}]
      {:i32, :lt_s, {first, second}}
    end

    def gt_s(first, second) do
      # [first, second, {:i32, :gt_s}]
      {:i32, :gt_s, {first, second}}
    end

    def eq(first, second) do
      {:i32, :eq, {first, second}}
    end

    def eqz() do
      {:i32, :eqz}
    end

    def load(offset), do: {:i32, :load, offset}
    def load8_u(offset), do: {:i32, :load8_u, offset}

    def store(offset), do: {:i32, :store, offset}

    def if_else(condition, do: when_true, else: when_false) do
      %IfElse{result: :i32, condition: condition, when_true: when_true, when_false: when_false}
    end
  end

  @primitive_types [:i32, :f32]

  def module(name, do: body) do
    %Module{name: name, body: body}
  end

  def module(name, body) do
    %Module{name: name, body: body}
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
    globals = Map.new(global_types)

    block_items =
      case block do
        {:__block__, _meta, block_items} -> block_items
        single -> [single]
      end

    block_items =
      Macro.prewalk(block_items, fn
        {:=, _meta1, [{global, _meta2, nil}, input]}
        when is_atom(global) and is_map_key(globals, global) ->
          [input, global_set(global)]

        {atom, meta, nil} when is_atom(atom) and is_map_key(globals, atom) ->
          {:global_get, meta, [atom]}

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

    # block = quote context: __CALLER__.module, do: unquote(block)
    definition = define_module(name, options, block)

    quote do
      Elixir.Module.put_attribute(__MODULE__, :wasm_module, unquote(definition))

      def lookup_data(:doctype), do: 4
      def lookup_data(:good_heading), do: 20
      def lookup_data(:bad_heading), do: 40

      def __wasm_module__(), do: unquote(definition)
      def to_wat(), do: ComponentsGuide.Rustler.WasmBuilder.to_wat(__wasm_module__())
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

    locals = Map.new(arg_types ++ local_types)

    block_items =
      case block do
        {:__block__, _meta, block_items} -> block_items
        single -> [single]
      end

    block_items = Macro.prewalk(block_items, &magic_func_item(&1, locals))

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

  # TODO: remove this one for local_get
  defp magic_func_item({f, meta, [{atom, _, nil}]}, locals)
       when f in [:local_get] and is_atom(atom) and is_map_key(locals, atom) do
    {f, meta, [atom]}
  end

  defp magic_func_item({:=, _meta1, [{local, _meta2, nil}, input]}, locals)
       when is_map_key(locals, local) do
    [magic_func_item(input, locals), local_set(local)]
  end

  defp magic_func_item({atom, meta, nil}, locals)
       when is_atom(atom) and is_map_key(locals, atom) do
    {:local_get, meta, [atom]}
  end

  defp magic_func_item(item, _locals) do
    item
  end

  def memory(name \\ nil, min) do
    %Memory{name: name, min: min}
  end

  def data(offset, value) do
    %Data{offset: offset, value: value, nil_terminated: false}
  end

  def data_nil_terminated(offset, value) do
    %Data{offset: offset, value: value, nil_terminated: true}
  end

  # defmacro data_nil_terminated(offset, key, values) do
  #   %Data{offset: offset, key: key, values: values, nil_terminated: true}
  # end

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
  def local_tee(identifier), do: {:local_tee, identifier}

  def if_(condition, do: when_true, else: when_false), do: {:if, condition, when_true, when_false}

  def call(f), do: {:call, f, []}

  defmacro defloop(identifier, options \\ [], do: block) do
    result_type = Keyword.get(options, :result, nil)

    block_items =
      case block do
        {:__block__, _meta, block_items} -> block_items
        single -> [single]
      end

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
    result_type = Keyword.get(options, :result, nil)

    block_items =
      case block do
        {:__block__, _meta, statements} -> statements
        statement -> [statement]
      end

    quote do
      %Block{
        identifier: unquote(identifier),
        result: unquote(result_type),
        body: unquote(block_items)
      }
    end
  end

  def br(identifier), do: {:br, identifier}
  def br_if(identifier, condition), do: {:br_if, identifier, condition}
  def br(identifier, if: condition), do: {:br_if, identifier, condition}

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

  def to_wat(%Data{offset: offset, value: value, nil_terminated: true}, indent) do
    [indent, "(data (i32.const ", to_string(offset), ") ", ?", value, ~S"\00", ?", ")"]
  end

  def to_wat(%Data{offset: offset, value: value, nil_terminated: false}, indent) do
    [indent, "(data (i32.const ", to_string(offset), ") ", ?", value, ?", ")"]
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
      ["  " <> indent, "(then", ?\n],
      ["    " <> indent, to_wat(when_true, ""), ?\n],
      ["  " <> indent, ")", ?\n],
      ["  " <> indent, "(else", ?\n],
      ["    " <> indent, to_wat(when_false, ""), ?\n],
      ["  " <> indent, ")", ?\n],
      [indent, ")"]
    ]
  end

  def to_wat({:if, condition, when_true, when_false}, indent) do
    [
      [indent, "(if ", to_wat(condition, ""), ?\n],
      ["  " <> indent, "(then", ?\n],
      ["    " <> indent, to_wat(when_true, ""), ?\n],
      ["  " <> indent, ")", ?\n],
      ["  " <> indent, "(else", ?\n],
      ["    " <> indent, to_wat(when_false, ""), ?\n],
      ["  " <> indent, ")", ?\n],
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
  def to_wat(:return, indent), do: [indent, "return"]
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
  def to_wat({:i32, op}, indent) when op in @i32_ops_all, do: "#{indent}(i32.#{op})"

  def to_wat({:i32, op, offset}, indent) when op in ~w(load load8_u store)a do
    [indent, "(i32.", to_string(op), " ", to_wat(offset), ?)]
  end

  def to_wat({:i32, op, {a, b}}, indent) when op in @i32_ops_2 do
    [indent, "(i32.", to_string(op), " ", to_wat(a), " ", to_wat(b), ?)]
  end

  def to_wat({:call, f, []}, indent), do: "#{indent}(call $#{f})"

  def to_wat({:br, identifier}, indent), do: [indent, "br $", to_string(identifier)]

  def to_wat({:br_if, identifier, condition}, indent),
    do: [indent, to_wat(condition), "\n", indent, "br_if $", to_string(identifier)]

  def to_wat({:br_if, identifier}, indent),
    do: [indent, "br_if $", to_string(identifier)]

  def to_wat({:return, value}, indent), do: [indent, "return ", to_wat(value)]

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
