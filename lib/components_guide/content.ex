defmodule ComponentsGuide.Content do
  alias ComponentsGuide.Content.Text
  alias ComponentsGuide.Content.TextImport
  alias ComponentsGuide.Fetch

  @cache_name :content_cache

  def list_content do
    query = Cachex.Query.create(true, { :key, :value })
    Cachex.stream!(@cache_name, query)
      |> Enum.map(fn {id, content} -> %Text{id: id, content: content} end)
  end

  def change_text(%Text{} = text) do
    Text.changeset(text)
  end

  defp build_text(params) do
    with {:ok, text} <- %Text{}
      |> Text.changeset(params)
      |> Ecto.Changeset.apply_action(:insert)
    do
      {:ok, %Text{text | id: :crypto.hash(:sha256, text.content)}}
    end
  end

  def create_text(params) do
    with {:ok, text} <- build_text(params),
      {:ok, _} <- Cachex.put(@cache_name, text.id, text.content)
    do
      {:ok, text}
    end
  end

  defp get_url(url) do
    Fetch.get_following_redirects!(url)
  end

  def import_text(params) do
    with changeset <- TextImport.changeset(%TextImport{}, params),
      {:ok, text_import} <- Ecto.Changeset.apply_action(changeset, :insert),
      response <- get_url(text_import.url),
      {:ok, text} <- build_text(%{ content: response.body }),
      {:ok, _} <- Cachex.put(@cache_name, text.id, text.content)
    do
      {:ok, text}
    end
  end

  defp decode_id(id_encoded), do: Base.url_decode64(id_encoded)

  def get_text!(id_encoded) do
    with {:ok, id} <- decode_id(id_encoded),
      {:ok, content} <- Cachex.get(@cache_name, id)
    do
      %Text{id: id, content: content}
    else
      _ -> raise Ecto.NoResultsError
    end
  end

  def delete_text(id_encoded) do
    with {:ok, id} <- decode_id(id_encoded)
    do
      Cachex.del(@cache_name, id)
    end
  end

  alias ComponentsGuide.Content.Text2

  @doc """
  Returns the list of texts2.

  ## Examples

      iex> list_texts2()
      [%Text2{}, ...]

  """
  def list_texts2 do
    Repo.all(Text2)
  end

  @doc """
  Gets a single text2.

  Raises `Ecto.NoResultsError` if the Text2 does not exist.

  ## Examples

      iex> get_text2!(123)
      %Text2{}

      iex> get_text2!(456)
      ** (Ecto.NoResultsError)

  """
  def get_text2!(id), do: Repo.get!(Text2, id)

  @doc """
  Creates a text2.

  ## Examples

      iex> create_text2(%{field: value})
      {:ok, %Text2{}}

      iex> create_text2(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_text2(attrs \\ %{}) do
    %Text2{}
    |> Text2.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a text2.

  ## Examples

      iex> update_text2(text2, %{field: new_value})
      {:ok, %Text2{}}

      iex> update_text2(text2, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_text2(%Text2{} = text2, attrs) do
    text2
    |> Text2.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a text2.

  ## Examples

      iex> delete_text2(text2)
      {:ok, %Text2{}}

      iex> delete_text2(text2)
      {:error, %Ecto.Changeset{}}

  """
  def delete_text2(%Text2{} = text2) do
    Repo.delete(text2)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking text2 changes.

  ## Examples

      iex> change_text2(text2)
      %Ecto.Changeset{data: %Text2{}}

  """
  def change_text2(%Text2{} = text2, attrs \\ %{}) do
    Text2.changeset(text2, attrs)
  end
end
