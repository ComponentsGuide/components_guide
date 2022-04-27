defmodule ComponentsGuideWeb.ComponentCase do
  @moduledoc """
  This module defines the test case to be used by
  component tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.LiveViewTest

      defdelegate find(el, selector), to: Floki
      defdelegate text(html), to: Floki

      def render_fragment(component, assigns) do
        html = render_component(component, assigns)
        {:ok, el} = Floki.parse_fragment(html)
        el
      end

      def count(el, selector) do
        find(el, selector) |> Enum.count()
      end
    end
  end

  setup _tags do
    :ok
  end
end
