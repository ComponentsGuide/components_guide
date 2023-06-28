defmodule Orb.I32.U8.Pointer do
  defstruct [:variable_reference]

  @behaviour Orb.Type
  @behaviour Access

  @impl Orb.Type
  def wasm_type(), do: :i32

  def byte_count(), do: 1
  def store_instruction(), do: :store8

  @impl Access
  def fetch(%Orb.VariableReference{} = var_ref, at!: offset) do
    ast = {:i32, :load8_u, Orb.I32.Add.neutralize(var_ref, offset)}
    {:ok, ast}
  end
end
