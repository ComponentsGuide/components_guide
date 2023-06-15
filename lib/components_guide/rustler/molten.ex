defmodule ComponentsGuide.Rustler.Molten do
  defmodule Native do
    use Rustler, otp_app: :components_guide, crate: "molten"

    def add(_, _), do: error()
    def js(_), do: error()
    def typescript_module(_, _, _), do: error()
    def parse_js(_), do: error()

    defp error, do: :erlang.nif_error(:nif_not_loaded)
  end

  def add(a, b), do: Native.add(a, b)
  def js(source), do: Native.js(source)

  def typescript_module(source) do
    ref = make_ref()
    Native.typescript_module(source, self(), ref)
  end

  def parse_js(source) do
    case Native.parse_js(source) do
      {:ok, json} -> {:ok, Jason.decode!(json)}
      other -> other
    end
  end
end
