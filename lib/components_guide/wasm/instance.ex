defmodule ComponentsGuide.Wasm.Instance do
  alias ComponentsGuide.Wasm

  require Logger

  defstruct [:elixir_mod, :exports, :handle]

  def run(mod, imports \\ []) do
    exports = Wasm.grouped_exports(mod)
    handle = Wasm.run_instance(mod, imports)
    %__MODULE__{elixir_mod: mod, exports: exports, handle: handle}
  rescue
    x in [RuntimeError] ->
      Logger.error(mod.to_wat())
      reraise x, __STACKTRACE__
  end

  defdelegate get_global(instance, global_name), to: Wasm, as: :instance_get_global
  defdelegate set_global(instance, global_name, new_value), to: Wasm, as: :instance_set_global

  defdelegate read_memory(instance, start, length), to: Wasm, as: :instance_read_memory
  defdelegate write_i32(instance, memory_offset, value), to: Wasm, as: :instance_write_i32
  defdelegate write_i64(instance, memory_offset, value), to: Wasm, as: :instance_write_i64

  defdelegate write_memory(instance, memory_offset, bytes),
    to: Wasm,
    as: :instance_write_memory

  defdelegate read_string_nul_terminated(instance, memory_offset),
    to: Wasm,
    as: :instance_read_string_nul_terminated

  defdelegate write_string_nul_terminated(instance, memory_offset, string),
    to: Wasm,
    as: :instance_write_string_nul_terminated

  defdelegate call(instance, f), to: Wasm, as: :instance_call
  defdelegate call(instance, f, a), to: Wasm, as: :instance_call
  defdelegate call(instance, f, a, b), to: Wasm, as: :instance_call
  defdelegate call(instance, f, a, b, c), to: Wasm, as: :instance_call

  defdelegate call_reading_string(instance, f), to: Wasm, as: :instance_call_returning_string
  defdelegate call_reading_string(instance, f, a), to: Wasm, as: :instance_call_returning_string

  # TODO: call Wasm.Native directly
  #   def call_reading_string(%__MODULE__{handle: handle}, f),
  #     do: Wasm.instance_call_returning_string(handle, f)
  # 
  #   def call_reading_string(%__MODULE__{handle: handle}, f, a),
  #     do: Wasm.instance_call_returning_string(handle, f, a)

  defdelegate call_reading_string(instance, f, a, b),
    to: Wasm,
    as: :instance_call_returning_string

  defdelegate call_reading_string(instance, f, a, b, c),
    to: Wasm,
    as: :instance_call_returning_string

  defdelegate call_stream_string_chunks(instance, f),
    to: Wasm,
    as: :instance_call_stream_string_chunks

  defdelegate call_joining_string_chunks(instance, f),
    to: Wasm,
    as: :instance_call_joining_string_chunks

  defmodule CaptureFuncError do
    defexception [:func_name, :instance]

    @impl true
    def message(%{func_name: func_name, instance: %{exports: %{func: funcs}}}) do
      func_names = Map.keys(funcs)
      "func #{func_name} not found in exports #{inspect(func_names)}"
    end
  end

  def capture(inst, f, arity) do
    f = to_string(f)

    case inst do
      %__MODULE__{exports: %{func: %{^f => _}}} ->
        nil

      %__MODULE__{} ->
        raise CaptureFuncError, func_name: f, instance: inst

      _ ->
        nil
    end

    wrap = &alloc_if_needed(inst, &1)

    # call = Function.capture(__MODULE__, :call, arity + 2)
    case arity do
      0 ->
        fn -> call(inst, f) end

      1 ->
        fn a -> call(inst, f, wrap.(a)) end

      2 ->
        fn a, b -> call(inst, f, wrap.(a), wrap.(b)) end

      3 ->
        fn a, b, c ->
          call(inst, f, wrap.(a), wrap.(b), wrap.(c))
        end
    end
  end

  def capture(inst, String, f, arity) do
    wrap = &alloc_if_needed(inst, &1)

    case arity do
      0 ->
        fn -> call_reading_string(inst, f) end

      1 ->
        fn a -> call_reading_string(inst, f, wrap.(a)) end

      2 ->
        fn a, b -> call_reading_string(inst, f, wrap.(a), wrap.(b)) end

      3 ->
        fn a, b, c ->
          call_reading_string(inst, f, wrap.(a), wrap.(b), wrap.(c))
        end
    end
  end

  defdelegate cast(instance, f), to: Wasm, as: :instance_cast
  defdelegate cast(instance, f, a), to: Wasm, as: :instance_cast
  defdelegate cast(instance, f, a, b), to: Wasm, as: :instance_cast
  defdelegate cast(instance, f, a, b, c), to: Wasm, as: :instance_cast

  def alloc_string(instance, string) do
    offset = call(instance, :alloc, byte_size(string) + 1)
    write_string_nul_terminated(instance, offset, string)
    offset
  end

  #   def alloc_list(instance, list) do
  #     items_encoded = encode_value(list)
  #     bytes = IO.iodata_to_binary(items_encoded)
  # 
  #     list_bytes =
  #       for item <- items_encoded do
  #         case item do
  #           item when is_binary(item) ->
  #             offset = call(instance, :alloc, byte_size(item))
  #             encode_value(offset)
  # 
  #           [a, b] when is_binary(a) and is_binary(b) ->
  #             offset_a = call(instance, :alloc, byte_size(a))
  #             offset_b = call(instance, :alloc, byte_size(b))
  #             offset_list = cons(instance, offset_a, offset_b)
  #             IO.inspect({offset_a, offset_b, offset_list})
  #             encode_value(offset_list)
  #         end
  #       end
  # 
  #     IO.inspect(list_bytes)
  #     list_bytes = IO.iodata_to_binary(list_bytes)
  # 
  #     {items_encoded, bytes, list_bytes}
  #     # offset = call(instance, :alloc, byte_size(items_bytes))
  #     # write_string_nul_terminated(instance, offset, string)
  #     # offset
  #   end

  def alloc_list(instance, []), do: 0x0

  def alloc_list(instance, [single]) when is_binary(single),
    do: cons(instance, alloc_string(instance, single), 0x0)

  def alloc_list(instance, [single]) when is_list(single),
    do: cons(instance, alloc_list(instance, single), 0x0)

  def alloc_list(instance, [head | tail]) when is_binary(head),
    do: cons(instance, alloc_string(instance, head), alloc_list(instance, tail))

  def alloc_list(instance, [head | tail]) when is_list(head),
    do: cons(instance, alloc_list(instance, head), alloc_list(instance, tail))

  defp cons(instance, head, tail) do
    offset_list = call(instance, :alloc, 8)
    write_i32(instance, offset_list, head)
    write_i32(instance, offset_list + 4, tail)
    offset_list
  end

  defp encode_value(s) when is_binary(s) do
    # TODO: should we align bytes?
    s <> <<0>>
  end

  defp encode_value(n) when is_integer(n) do
    # TODO: Assumes 32-bit numbers
    # WebAssembly is little endian
    <<n::little-size(32)>>
  end

  defp encode_value(l) when is_list(l) do
    for item <- l, do: encode_value(item)
  end

  defp alloc_if_needed(inst, value) when is_binary(value), do: alloc_string(inst, value)
  defp alloc_if_needed(_inst, value), do: value

  def log_memory(instance, start, length) do
    bytes = read_memory(instance, start, length)
    hex = Base.encode16(bytes)
    hex_pretty = hex |> String.to_charlist() |> Stream.chunk_every(8) |> Enum.join(" ")
    IO.inspect(hex_pretty, limit: :infinite, label: "Wasm instance memory")
    # IO.inspect(bytes, base: :hex, label: "Wasm instance memory")
  end

  def exports(instance) do
    Wasm.list_exports(instance.elixir_mod)
  end

  defimpl String.Chars do
    def to_string(instance) do
      exports = Wasm.list_exports(instance.elixir_mod)

      to_string = List.keyfind(exports, "to_string", 1)
      next_body_chunk = List.keyfind(exports, "next_body_chunk", 1)

      cond do
        match?({:func, _}, to_string) ->
          Wasm.Instance.call_reading_string(instance, :to_string)

        match?({:func, _}, next_body_chunk) ->
          Wasm.Instance.call_stream_string_chunks(instance, :next_body_chunk) |> Enum.join()

        true ->
          nil
      end
    end
  end

  defmodule Caller do
    defdelegate read_string_nul_terminated(caller, memory_offset),
      to: Wasm.WasmNative,
      as: :wasm_caller_read_string_nul_terminated
  end
end
