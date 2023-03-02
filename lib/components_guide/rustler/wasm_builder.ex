defmodule ComponentsGuide.Rustler.WasmBuilder do
  defmacro __using__(_) do
    quote do
      import ComponentsGuide.Rustler.WasmBuilder
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
    define_module(call, block)
  end

  defp define_module(call, block) do
    block_items =
      case block do
        {:__block__, [], block_items} -> block_items
        single -> [single]
      end

    {name, _args} = Macro.decompose_call(call)

    quote do
      %Module{name: unquote(name), body: unquote(block_items)}
    end
  end

  defmacro func(call, options \\ [], do: block) do
    define_func(call, :public, options, block)
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
            case block_item do
              {f, meta, [{atom, _, nil}]}
              when f in [:local_get] and is_atom(atom) and is_map_key(locals, atom) ->
                {f, meta, [atom]}

              _ ->
                block_item
            end
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

  def memory(name \\ nil, min) do
    %Memory{name: name, min: min}
  end

  def data(offset, value) do
    %Data{offset: offset, value: value}
  end

  def wasm_import(module, name, type) do
    %Import{module: module, name: name, type: type}
  end

  def make_func(name = {:export, _}, result = {:result, _}, body) do
    %Func{name: name, params: [], result: result, body: body}
  end

  def make_func(name = {:export, _}, param = %Param{}, result = {:result, _}, body) do
    %Func{name: name, params: [param], result: result, body: body}
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
  def i32(:mul), do: {:i32, :mul}

  def local_get(identifier), do: {:local_get, identifier}

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
  def to_wat({:local_get, identifier}, indent), do: "#{indent}local.get $#{identifier}"
  def to_wat(value, indent) when is_integer(value), do: "#{indent}i32.const #{value}"
  def to_wat(value, indent) when is_float(value), do: "#{indent}f32.const #{value}"
  def to_wat({:i32, :mul}, indent), do: "#{indent}i32.mul"
end
