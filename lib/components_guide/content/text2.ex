defmodule ComponentsGuide.Content.Text2 do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :content, :string

    timestamps()
  end

  @doc false
  def changeset(text2, attrs) do
    text2
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
