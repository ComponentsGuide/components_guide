defmodule ComponentsGuideWeb.ResearchView do
  use ComponentsGuideWeb, :view

  def results(query) do
    ~E"""
    Content!
    """
  end

  defdelegate float_to_string(f, options), to: :erlang, as: :float_to_binary

  def humanize_bytes(count) when count >= 1024 * 1024 do
    megabytes = count / (1024 * 1024)
    "#{float_to_string(megabytes, decimals: 1)} mB"
  end

  def humanize_bytes(count) when count >= 1024 do
    kilobytes = count / 1024
    "#{float_to_string(kilobytes, decimals: 1)} kB"
  end

  def humanize_bytes(count) when is_integer(count) do
    "#{count} B"
  end
end
