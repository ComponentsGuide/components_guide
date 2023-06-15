defmodule ComponentsGuide.Content.Text do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :content, :string
  end

  def changeset(%ComponentsGuide.Content.Text{} = text, params \\ %{}) do
    text
    |> cast(params, [:content])
    |> validate_required([:content])
  end

  def to_param(%ComponentsGuide.Content.Text{id: id}) do
    Base.url_encode64(id)
  end

  def to_param(%ComponentsGuide.Content.Text{content: content}) when is_binary(content) do
    Base.url_encode64(:crypto.hash(:sha256, content))
  end
end

# defimpl Phoenix.Param, for: ComponentsGuide.Content.Text do
#   def to_param(%ComponentsGuide.Content.Text{id: id}) do
#     Base.url_encode64(id)
#   end

#   def to_param(%ComponentsGuide.Content.Text{content: content}) when is_binary(content) do
#     Base.url_encode64(:crypto.hash(:sha256, content))
#   end
# end
