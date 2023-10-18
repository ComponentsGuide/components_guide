defmodule ComponentsGuide.CollectedRepo do
  def has?(_content_id), do: raise(:todo)
  def get!(_content_id), do: raise(:todo)

  def run_isolated!(_content_id), do: raise(:todo)

  def new_module(_content_id, _imports), do: raise(:unimplemented)
  # Replace with a gen server
  def start_module(_module), do: raise(:unimplemented)
end
