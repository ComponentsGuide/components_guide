defmodule ComponentsGuide.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ComponentsGuide.Content` context.
  """

  @doc """
  Generate a text2.
  """
  def text2_fixture(attrs \\ %{}) do
    {:ok, text2} =
      attrs
      |> Enum.into(%{
        content: "some content"
      })
      |> ComponentsGuide.Content.create_text2()

    text2
  end
end
