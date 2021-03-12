defmodule ComponentsGuideWeb.FormattingHelpers do
  defdelegate float_to_string(f, options), to: :erlang, as: :float_to_binary

  def humanize_bytes(count) when is_integer(count) and count >= 1024 * 1024 do
    megabytes = count / (1024 * 1024)
    "#{float_to_string(megabytes, decimals: 1)} mB"
  end

  def humanize_bytes(count) when is_integer(count) and count >= 1024 do
    kilobytes = count / 1024
    "#{float_to_string(kilobytes, decimals: 1)} kB"
  end

  def humanize_bytes(count) when is_integer(count) do
    "#{count} B"
  end

  def humanize_count(count) when is_integer(count) and count >= 1_000_000 do
    formatted = count / 1_000_000
    "#{float_to_string(formatted, decimals: 1)}M"
  end

  def humanize_count(count) when is_integer(count) and count >= 1000 do
    formatted = count / 1000
    "#{float_to_string(formatted, decimals: 1)}K"
  end

  def humanize_count(count) when is_integer(count) do
    "#{count}"
  end
end
