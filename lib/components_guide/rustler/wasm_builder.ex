defmodule ComponentsGuide.Rustler.WasmBuilder do
  defmacro __using__(_) do
    quote do
      import ComponentsGuide.Rustler.WasmBuilder
      alias ComponentsGuide.Rustler.WasmBuilder.{I32}
    end
  end

  defmodule Module do
    defstruct [:name, :body]
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

  defmodule Func do
    defstruct [:name, :params, :result, :body]
  end

  defmodule Param do
    defstruct [:name, :type]
  end

  @i32_ops_2 ~w(mul add lt_s gt_s or)a
  @i32_ops ~w(mul add lt_s gt_s or eqz)a

  defmodule I32 do
    def unquote(:or)(first, second) do
      # [first, second, {:i32, :or}]
      {:i32, :or, {first, second}}
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
    define_module(Macro.to_string(call), block)
  end

  defp define_module(name, block) do
    block_items =
      case block do
        {:__block__, [], block_items} -> block_items
        single -> [single]
      end

    quote do
      %Module{name: unquote(name), body: unquote(block_items)}
    end
  end

  defmacro defwasm(do: block) do
    name = __CALLER__.module |> Elixir.Module.split() |> List.last()

    definition = define_module(name, block)

    quote do
      Elixir.Module.put_attribute(__MODULE__, :wasm_module, unquote(definition))

      def __wasm_module__(), do: unquote(definition)
    end
  end

  defmacro func(call, options \\ [], do: block) do
    define_func(call, :public, options, block)
  end

  defp define_func(call, visibility, options, block) do
    {name, args} = Macro.decompose_call(call)

    # if name == :validate do
    #   IO.inspect(block)
    # end

    name =
      case visibility do
        :public -> export(name)
        :private -> name
      end

    params =
      for {name, _meta, [type]} <- args do
        Macro.escape(param(name, type))
      end

    locals =
      Map.new(
        for {name, _meta, [type]} <- args do
          {name, type}
        end
      )

    block_items =
      case block do
        {:__block__, _meta, block_items} ->
          for block_item <- block_items do
            magic_func_item(block_item, locals)
          end

        single ->
          [single]
      end

    result_type = Keyword.get(options, :result, :i32)

    quote do
      %Func{
        name: unquote(name),
        params: unquote(params),
        result: result(unquote(result_type)),
        body: unquote(block_items)
      }
    end
  end

  defp magic_func_item({f, meta, [{atom, _, nil}]}, params)
       when f in [:local_get] and is_atom(atom) and is_map_key(params, atom) do
    {f, meta, [atom]}
  end

  defp magic_func_item(
         {{:., meta1, [{:__aliases__, meta2, [:I32]}, op]}, meta3, [{atom, meta4, nil}, b]},
         params
       )
       when is_atom(atom) and is_map_key(params, atom) and op in @i32_ops_2 do
    {{:., meta1, [{:__aliases__, meta2, [:I32]}, op]}, meta3, [{:local_get, meta4, [atom]}, b]}
  end

  defp magic_func_item({:=, _meta1, [{local, _meta2, nil}, input]}, params) do
    [magic_func_item(input, params), local_set(local)]
  end

  defp magic_func_item(item, _params) do
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
  def i32(op) when op in @i32_ops, do: {:i32, op}

  def local(identifier, type), do: {:local, identifier, type}
  def local_get(identifier), do: {:local_get, identifier}
  def local_set(identifier), do: {:local_set, identifier}

  def to_wat(term) when is_atom(term), do: to_wat(term.__wasm_module__(), "")
  def to_wat(term), do: to_wat(term, "")

  def to_wat(term, indent)

  def to_wat(list, indent) when is_list(list) do
    Enum.map(list, &to_wat(&1, indent)) |> Enum.join("\n")
  end

  def to_wat(%Module{name: name, body: body}, indent) do
    ~s"""
    #{indent}(module $#{name}
    #{indent}#{to_wat(body, "  " <> indent)}
    #{indent})
    """
  end

  def to_wat(%Import{module: module, name: name, type: type}, indent) do
    ~s[#{indent}(import "#{module}" "#{name}" #{to_wat(type)})]
  end

  def to_wat(%Memory{name: nil, min: min}, indent) do
    ~s[#{indent}(memory #{min})]
  end

  def to_wat(%Data{offset: offset, value: value}, indent) do
    ~s[#{indent}(data (i32.const #{offset}) "#{value}")]
  end

  def to_wat(%Memory{name: name, min: min}, indent) do
    ~s"#{indent}(memory #{to_wat(name)} #{min})"
  end

  def to_wat(%Func{name: name, params: params, result: result, body: body}, indent) do
    ~s"""
    #{indent}(func #{to_wat(name)} #{for param <- params, do: [to_wat(param), " "]}#{to_wat(result)}
    #{to_wat(body, "  " <> indent)}
    #{indent})\
    """
  end

  def to_wat(%Param{name: name, type: type}, indent) do
    ~s"#{indent}(param $#{name} #{type})"
  end

  def to_wat({:export, name}, _indent), do: "(export \"#{name}\")"
  def to_wat({:result, value}, _indent), do: "(result #{value})"
  def to_wat({:i32_const, value}, indent), do: "#{indent}i32.const #{value}"
  def to_wat({:local, identifier, type}, indent), do: "#{indent}(local $#{identifier} #{type})"
  def to_wat({:local_get, identifier}, indent), do: "#{indent}local.get $#{identifier}"
  def to_wat({:local_set, identifier}, indent), do: "#{indent}local.set $#{identifier}"
  def to_wat(value, indent) when is_integer(value), do: "#{indent}i32.const #{value}"
  def to_wat(value, indent) when is_float(value), do: "#{indent}f32.const #{value}"
  def to_wat({:i32, op}, indent) when op in @i32_ops, do: "#{indent}i32.#{op}"

  def to_wat({:i32, op, {a, b}}, indent) when op in @i32_ops_2,
    do: "#{indent}(i32.#{op} (#{to_wat(a)}) (#{to_wat(b)}))"
end
