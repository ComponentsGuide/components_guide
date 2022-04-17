defmodule ComponentsGuide.Rustler.Math do
  use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math

  def add(_, _), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
