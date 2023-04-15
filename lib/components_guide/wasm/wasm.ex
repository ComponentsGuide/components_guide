defmodule ComponentsGuide.Wasm do
  import ComponentsGuide.Wasm.WasmNative

  defmacro __using__(_) do
    quote do
      use ComponentsGuide.WasmBuilder

      # @on_load :validate_definition!
      # @after_compile __MODULE__

      # def __after_compile__(_env, _bytecode) do
      #   validate_definition!()
      # end

      def validate_definition! do
        ComponentsGuide.Wasm.validate_definition!(__MODULE__.to_wat())
      end

      def to_wasm() do
        ComponentsGuide.Wasm.wat2wasm(__MODULE__)
      end

      def exports do
        ComponentsGuide.Wasm.list_exports(__MODULE__)
      end

      def start() do
        ComponentsGuide.Wasm.run_instance(__MODULE__)
      end
    end
  end

  def list_exports(source) do
    source =
      case process_source(source) do
        {:wat, _} = value -> value
        other -> {:wat, other}
      end

    wasm_list_exports(source)
  end

  def wat2wasm(source), do: process_source(source) |> ComponentsGuide.Wasm.WasmNative.wat2wasm()

  def validate_definition!(source) do
    source = {:wat, process_source(source)}

    case ComponentsGuide.Wasm.WasmNative.validate_module_definition(source) do
      {:error, reason} -> raise reason
      _ -> nil
    end
  end

  # def call(source, f) do
  #   process_source(source) |> wasm_call(f, []) |> process_result2()
  # end

  # def call(source, f, a) do
  #   args = [a] |> Enum.map(&transform_primitive/1)
  #   process_source(source) |> wasm_call(f, args) |> process_result2()
  # end

  # def call(source, f, a, b) do
  #   args = [a, b] |> Enum.map(&transform_primitive/1)
  #   process_source(source) |> wasm_call(f, args) |> process_result2()
  # end

  # def call(source, f, a, b, c) do
  #   args = [a, b, c] |> Enum.map(&transform_primitive/1)
  #   process_source(source) |> wasm_call(f, args) |> process_result2()
  # end

  def call(source, f) do
    process_source(source) |> wasm_call_i32(f, []) |> process_result()
  end

  def call(source, f, a) do
    process_source(source) |> wasm_call_i32(f, [a]) |> process_result()
  end

  def call(source, f, a, b) do
    process_source(source) |> wasm_call_i32(f, [a, b]) |> process_result()
  end

  def call(source, f, a, b, c) do
    process_source(source) |> wasm_call_i32(f, [a, b, c]) |> process_result()
  end

  def call_apply(source, f, args) do
    args = Enum.map(args, &transform_primitive/1)
    call_apply_raw(source, f, args)
  end

  def call_apply_raw(source, f, args) do
    process_source(source) |> wasm_call(f, args) |> process_result2()
  end

  # defp transform_primitive(a)
  defp transform_primitive(a) when is_integer(a), do: {:i32, a}
  defp transform_primitive(a) when is_float(a), do: {:f32, a}

  def call_string(source, f), do: process_source(source) |> wasm_call_i32_string(f, [])
  def call_string(source, f, a), do: process_source(source) |> wasm_call_i32_string(f, [a])
  def call_string(source, f, a, b), do: process_source(source) |> wasm_call_i32_string(f, [a, b])

  def bulk_call(source, calls) do
    for result <- process_source(source) |> wasm_call_bulk(calls) do
      process_result(result)
    end
  end

  def steps(source, steps) do
    wat = process_source(source)
    results = wat |> wasm_steps(steps)

    case results do
      {:error, reason} ->
        {:error, reason, wat}

      results when is_list(results) ->
        for result <- results do
          case result do
            [] -> nil
            list when is_list(list) -> IO.iodata_to_binary(list)
            other -> other
          end
        end
    end
  end

  def run_instance(source) do
    source = {:wat, process_source(source)}
    wasm_run_instance(source)
  end

  def instance_get_global(instance, global_name),
    do: wasm_instance_get_global_i32(instance, to_string(global_name))

  def instance_set_global(instance, global_name, new_value),
    do: wasm_instance_set_global_i32(instance, to_string(global_name), new_value)

  # def instance_call(instance, f), do: wasm_instance_call_func(instance, f)
  def instance_call(instance, f), do: wasm_instance_call_func_i32(instance, f, [])
  def instance_call(instance, f, a), do: wasm_instance_call_func_i32(instance, f, [a])
  def instance_call(instance, f, a, b), do: wasm_instance_call_func_i32(instance, f, [a, b])
  def instance_call(instance, f, a, b, c), do: wasm_instance_call_func_i32(instance, f, [a, b, c])

  def instance_call_returning_string(instance, f),
    do: wasm_instance_call_func_i32_string(instance, f, [])

  def instance_call_returning_string(instance, f, a),
    do: wasm_instance_call_func_i32_string(instance, f, [a])

  def instance_call_returning_string(instance, f, a, b),
    do: wasm_instance_call_func_i32_string(instance, f, [a, b])

  def instance_call_returning_string(instance, f, a, b, c),
    do: wasm_instance_call_func_i32_string(instance, f, [a, b, c])

  def instance_call_stream_string_chunks(instance, f) do
    Stream.unfold(0, fn n ->
      case instance_call_returning_string(instance, f) do
        "" -> nil
        s -> {s, n + 1}
      end
    end)
  end

  def instance_write_string_nul_terminated(instance, memory_offset, string)
      when is_integer(memory_offset) do
    wasm_instance_write_string_nul_terminated(instance, memory_offset, string)
  end

  def instance_write_string_nul_terminated(instance, global_name, string)
      when is_atom(global_name) do
    memory_offset = wasm_instance_get_global_i32(instance, to_string(global_name))
    wasm_instance_write_string_nul_terminated(instance, memory_offset, string)
  end

  def instance_read_memory(instance, start, length)
      when is_integer(start) and is_integer(length) do
    wasm_instance_read_memory(instance, start, length)
  end

  def instance_read_memory(instance, start_global_name, length)
      when is_atom(start_global_name) and is_integer(length) do
    start = wasm_instance_get_global_i32(instance, to_string(start_global_name))
    wasm_instance_read_memory(instance, start, length)
  end

  defp process_source(string) when is_binary(string), do: string
  defp process_source({:wat, string} = value) when is_binary(string), do: value

  defp process_source(atom) when is_atom(atom), do: atom.to_wat()

  # do: ComponentsGuide.WasmBuilder.to_wat(atom)

  defp process_result([]), do: nil
  defp process_result([a]), do: a

  defp process_result(multiple_items) when is_list(multiple_items),
    do: List.to_tuple(multiple_items)

  defp process_result({:error, "failed to parse WebAssembly module"}), do: {:error, :parse}
  defp process_result({:error, s}), do: {:error, s}

  defp process_value({:i32, a}), do: a
  defp process_value({:f32, a}), do: a

  defp process_result2([]), do: nil
  defp process_result2([a]), do: process_value(a)

  defp process_result2(multiple_items) when is_list(multiple_items),
    do: List.to_tuple(multiple_items |> Enum.map(&process_value/1))

  defp process_result2({:error, "failed to parse WebAssembly module"}), do: {:error, :parse}
  defp process_result2({:error, s}), do: {:error, s}
end
