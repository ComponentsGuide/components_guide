defmodule ComponentsGuideWeb.PrimitiveHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML
  use Phoenix.Component

  def code_block(assigns) do
    # assigns = %{}
    # content_tag(:pre, inspect(assigns))
    ~H"""
    <pre class={"language-#{@lang}"}><code><%=
      if assigns[:code] do
        assigns[:code]
      else
        render_slot(@inner_block) |> then(fn
          %{static: [code]} -> String.trim(code)
          %{static: strings} when is_list(strings) -> strings |> Enum.join() |> String.trim()
        end)
      end
    %></code></pre>
    """
  end
end
