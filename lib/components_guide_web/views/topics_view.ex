defmodule ComponentsGuideWeb.TopicsView do
  use ComponentsGuideWeb, :view

  defp subject_to_module(:accessibility_first), do: ComponentsGuideWeb.AccessibilityFirstView
  defp subject_to_module(:react_typescript), do: ComponentsGuideWeb.ReactTypescriptView
  defp subject_to_module(:robust_javascript_interactivity), do: ComponentsGuideWeb.RobustJavascriptInteractivityView
  defp subject_to_module(:web_standards), do: ComponentsGuideWeb.WebStandardsView
  defp subject_to_module(:composable_systems), do: ComponentsGuideWeb.ComposableSystemsView

  @backgrounds %{
    accessibility_first: "bg-violet-200",
    react_typescript: "bg-blue-200",
    robust_javascript_interactivity: "bg-orange-200",
    web_standards: "bg-yellow-200",
    composable_systems: "bg-green-200",
  }

  def class_for_topic(topic), do: @backgrounds[topic]
end
