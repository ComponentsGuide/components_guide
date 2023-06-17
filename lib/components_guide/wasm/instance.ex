defmodule ComponentsGuide.Wasm.Instance do
  alias ComponentsGuide.Wasm

  require Logger

  defstruct [:elixir_mod, :handle]

  def run(mod) do
    handle = ComponentsGuide.Wasm.run_instance(mod)
    %__MODULE__{elixir_mod: mod, handle: handle}
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
  def call_reading_string(%__MODULE__{handle: handle}, f),
    do: Wasm.instance_call_returning_string(handle, f)

  def call_reading_string(%__MODULE__{handle: handle}, f, a),
    do: Wasm.instance_call_returning_string(handle, f, a)

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

  def capture(inst, f, arity) do
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

  def capture_reading_string(inst, f, arity) do
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

  def alloc_string(instance, string) do
    offset = call(instance, :alloc, byte_size(string) + 1)
    write_string_nul_terminated(instance, offset, string)
    offset
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
end
