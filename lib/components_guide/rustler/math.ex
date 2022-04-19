defmodule ComponentsGuide.Rustler.Math do
  use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math
  use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math, target_dir: System.tmp_dir!()
  # use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math, cargo: {:rustup, :stable}

  def add(_, _), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
