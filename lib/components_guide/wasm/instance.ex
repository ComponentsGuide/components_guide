defmodule ComponentsGuide.Wasm.Instance do
  alias ComponentsGuide.Wasm

  defdelegate get_global(instance, global_name), to: Wasm, as: :instance_get_global
  defdelegate set_global(instance, global_name, new_value), to: Wasm, as: :instance_set_global

  defdelegate read_memory(instance, start, length), to: Wasm, as: :instance_read_memory
  defdelegate write_i32(instance, memory_offset, value), to: Wasm, as: :instance_write_i32

  defdelegate write_string_nul_terminated(instance, memory_offset, string),
    to: Wasm,
    as: :instance_write_string_nul_terminated

  defdelegate call(instance, f), to: Wasm, as: :instance_call
  defdelegate call(instance, f, a), to: Wasm, as: :instance_call
  defdelegate call(instance, f, a, b), to: Wasm, as: :instance_call
  defdelegate call(instance, f, a, b, c), to: Wasm, as: :instance_call

  def log_memory(instance, start, length) do
    bytes = read_memory(instance, start, length)
    hex = Base.encode16(bytes)
    hex_pretty = hex |> String.to_charlist() |> Stream.chunk_every(4) |> Enum.join(" ")
    IO.inspect(hex_pretty, limit: :infinite, label: "Wasm instance memory")
    # IO.inspect(bytes, base: :hex, label: "Wasm instance memory")
  end
end
