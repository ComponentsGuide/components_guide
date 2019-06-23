defmodule App do
  def restart do
    Application.stop(:components_guide)
    Application.stop(:components_guide_web)
    recompile()
    Application.ensure_all_started(:components_guide)
    Application.ensure_all_started(:components_guide_web)
  end
end
