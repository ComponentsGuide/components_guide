defmodule ComponentsGuide.Rustler.Wasm do
  # if false and Mix.env() == :dev do
  use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math

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

  def wasm_example_n_i32(_, _, _), do: error()
  def wasm_example_0(_, _), do: error()
  def wasm_string_i32(_, _, _), do: error()

  def call(source, f) do
    process_source(source) |> wasm_example_n_i32(f, []) |> process_result()
  end

  def call(source, f, a) do
    process_source(source) |> wasm_example_n_i32(f, [a]) |> process_result()
  end

  def call(source, f, a, b) do
    process_source(source) |> wasm_example_n_i32(f, [a, b]) |> process_result()
  end

  def call_string(source, f), do: wasm_string_i32(source, f, [])
  def call_string(source, f, a), do: wasm_string_i32(source, f, [a])
  def call_string(source, f, a, b), do: wasm_string_i32(source, f, [a, b])

  defp error, do: :erlang.nif_error(:nif_not_loaded)

  defp process_source(string) when is_binary(string), do: string

  defp process_source(atom) when is_atom(atom),
    do: ComponentsGuide.Rustler.WasmBuilder.to_wat(atom)

  defp process_result([]), do: nil
  defp process_result([a]), do: a

  defp process_result(multiple_items) when is_list(multiple_items),
    do: List.to_tuple(multiple_items)

  defp process_result({:error, "failed to parse WebAssembly module"}), do: {:error, :parse}
  defp process_result({:error, s}), do: {:error, s}
end
