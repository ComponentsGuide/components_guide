defmodule ComponentsGuide.Wasm.Instance do
  alias ComponentsGuide.Wasm

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
    # call = Function.capture(__MODULE__, :call, arity + 2)
    case arity do
      0 -> fn -> call(inst, f) end
      1 -> fn a -> call(inst, f, a) end
      2 -> fn a, b -> call(inst, f, a, b) end
      3 -> fn a, b, c -> call(inst, f, a, b, c) end
    end
  end

  def capture_reading_string(inst, f, arity) do
    case arity do
      0 -> fn -> call_reading_string(inst, f) end
      1 -> fn a -> call_reading_string(inst, f, a) end
      2 -> fn a, b -> call_reading_string(inst, f, a, b) end
      3 -> fn a, b, c -> call_reading_string(inst, f, a, b, c) end
    end
  end

  def alloc_string(instance, string) do
    offset = call(instance, :alloc, byte_size(string) + 1)
    write_string_nul_terminated(instance, offset, string)
    offset
  end

  def log_memory(instance, start, length) do
    bytes = read_memory(instance, start, length)
    hex = Base.encode16(bytes)
    hex_pretty = hex |> String.to_charlist() |> Stream.chunk_every(8) |> Enum.join(" ")
    IO.inspect(hex_pretty, limit: :infinite, label: "Wasm instance memory")
    # IO.inspect(bytes, base: :hex, label: "Wasm instance memory")
  end
end
