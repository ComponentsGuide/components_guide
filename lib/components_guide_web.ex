defmodule ComponentsGuideWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use ComponentsGuideWeb, :controller
      use ComponentsGuideWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: ComponentsGuideWeb

      import Plug.Conn
      import ComponentsGuideWeb.Gettext
      import Phoenix.LiveView.Controller
      alias ComponentsGuideWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/components_guide_web/templates",
        namespace: ComponentsGuideWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      import Phoenix.Component

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def live_view(opts \\ []) do
    quote do
      @opts Keyword.merge(
              [
                layout: {ComponentsGuideWeb.LayoutView, "live.html"},
                container: {:div, class: "relative h-screen flex overflow-hidden"}
              ],
              unquote(opts)
            )
      use Phoenix.LiveView, @opts

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import ComponentsGuideWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import ComponentsGuideWeb.ErrorHelpers
      import ComponentsGuideWeb.Gettext
      alias ComponentsGuideWeb.Router.Helpers, as: Routes

      import Paredown
      import ComponentsGuideWeb.LinkHelpers
      import ComponentsGuideWeb.AssetsHelpers
      alias ComponentsGuideWeb.StylingHelpers, as: Styling
      alias ComponentsGuideWeb.FormattingHelpers, as: Format
      # alias ComponentsGuideWeb.PrimitiveHelpers, as: Primitives

      def markdown!(markdown) do
        Earmark.as_html!(markdown)
        |> raw()
      end

      def include_fragment(src), do: content_tag("include-fragment", [], src: src)

      def dev_inspect(value) do
        content_tag("pre", inspect(value, pretty: true))
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
