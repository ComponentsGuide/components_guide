defmodule ComponentsGuide.Rustler.Math do
  # use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math
  # use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math, target_dir: System.tmp_dir!()
  # use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math, cargo: {:rustup, :stable}

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :rustler_precompilation_example,
    crate: "example",
    base_url:
      "https://github.com/ComponentsGuide/components_guide/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_PRECOMPILATION_EXAMPLE_BUILD") in ["1", "true"],
    version: version

  def add(_, _), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
