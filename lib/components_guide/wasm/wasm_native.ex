defmodule ComponentsGuide.Wasm.WasmNative do
  # if false and Mix.env() == :dev do
  use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math

  defp error, do: :erlang.nif_error(:nif_not_loaded)

  #   # use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math, target_dir: System.tmp_dir!()
  #   # use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math, cargo: {:rustup, :stable}
  # end

  # if false and Mix.env() == :prod do
  #   app = Mix.Project.config()[:app]
  #   version = Mix.Project.config()[:version]

  #   use RustlerPrecompiled,
  #     otp_app: app,
  #     crate: "componentsguide_rustler_math",
  #     base_url: "https://github.com/ComponentsGuide/components_guide/releases/download/v#{version}",
  #     force_build: System.get_env("RUSTLER_PRECOMPILATION_EXAMPLE_BUILD") in ["1", "true"],
  #     version: version
  # end

  def add(_, _), do: error()
  def reverse_string(_), do: error()

  def wasm_list_exports(_), do: error()
  def wasm_list_imports(_), do: error()

  def wasm_call_i32(_, _, _), do: error()
  def wasm_call(_, _, _), do: error()
  def wasm_call_void(_, _), do: error()
  def wasm_call_i32_string(_, _, _), do: error()

  def wasm_call_bulk(_, _), do: error()
  def wasm_steps(_, _), do: error()

  def wasm_run_instance(_, _, _, _), do: error()
  def wasm_instance_get_global_i32(_, _), do: error()
  def wasm_instance_set_global_i32(_, _, _), do: error()
  def wasm_instance_call_func(_, _), do: error()
  def wasm_instance_call_func_i32(_, _, _), do: error()
  def wasm_instance_call_func_i32_string(_, _, _), do: error()
  def wasm_instance_cast_func_i32(_, _, _), do: error()
  def wasm_instance_write_i32(_, _, _), do: error()
  def wasm_instance_write_i64(_, _, _), do: error()
  def wasm_instance_write_memory(_, _, _), do: error()
  def wasm_instance_write_string_nul_terminated(_, _, _), do: error()
  def wasm_instance_read_memory(_, _, _), do: error()
  def wasm_instance_read_string_nul_terminated(_, _), do: error()
  def wasm_call_out_reply(_, _), do: error()
  def wasm_caller_read_string_nul_terminated(_, _), do: error()

  def wat2wasm(_), do: error()
  def validate_module_definition(_), do: error()
end
