defmodule Orb.Type do
  @callback wasm_type() :: :i32 | :f32
end
