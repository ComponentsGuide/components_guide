defmodule ComponentsGuide.CollectedRepo do
  def has?(_content_id), do: raise(:todo)
  def get!(_content_id), do: raise(:todo)

  def run_isolated!(_content_id), do: raise(:todo)

  def new_instance_definition(_content_id, _imports), do: raise(:unimplemented)
  # Replace with a gen server
  def start_instance(_instance_definition), do: raise(:unimplemented)
end
