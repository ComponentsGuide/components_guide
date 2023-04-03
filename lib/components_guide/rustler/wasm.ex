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

  def wasm_call_bulk(_, _), do: error()
  def wasm_steps(_, _), do: error()

  def wasm_run_instance(_), do: error()
  def wasm_instance_call_func(_, _), do: error()
  def wasm_instance_call_func_i32(_, _, _), do: error()
  def wasm_instance_read_memory(_, _, _), do: error()

  def wat2wasm(_), do: error()

  def call(source, f) do
    process_source(source) |> wasm_example_n_i32(f, []) |> process_result()
  end

  def call(source, f, a) do
    process_source(source) |> wasm_example_n_i32(f, [a]) |> process_result()
  end

  def call(source, f, a, b) do
    process_source(source) |> wasm_example_n_i32(f, [a, b]) |> process_result()
  end

  def call_string(source, f), do: process_source(source) |> wasm_string_i32(f, [])
  def call_string(source, f, a), do: process_source(source) |> wasm_string_i32(f, [a])
  def call_string(source, f, a, b), do: process_source(source) |> wasm_string_i32(f, [a, b])

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

  def instance_call_func(instance, f), do: wasm_instance_call_func(instance, f)
  def instance_call_func(instance, f, a), do: wasm_instance_call_func_i32(instance, f, [a])
  def instance_call_func(instance, f, a, b), do: wasm_instance_call_func_i32(instance, f, [a, b])
  def instance_call_func(instance, f, a, b, c), do: wasm_instance_call_func_i32(instance, f, [a, b, c])

  def instance_read_memory(instance, start, length) do
    wasm_instance_read_memory(instance, start, length)
  end

  defp error, do: :erlang.nif_error(:nif_not_loaded)

  defp process_source(string) when is_binary(string), do: string

  defp process_source(atom) when is_atom(atom),
    do: atom.to_wat()
    # do: ComponentsGuide.Rustler.WasmBuilder.to_wat(atom)

  defp process_result([]), do: nil
  defp process_result([a]), do: a

  defp process_result(multiple_items) when is_list(multiple_items),
    do: List.to_tuple(multiple_items)

  defp process_result({:error, "failed to parse WebAssembly module"}), do: {:error, :parse}
  defp process_result({:error, s}), do: {:error, s}
end
