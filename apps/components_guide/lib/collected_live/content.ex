defmodule ComponentsGuide.Content do
  alias ComponentsGuide.Content.Text
  alias ComponentsGuide.Content.TextImport

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
    HTTPotion.get(url, follow_redirects: true)
  end

  def import_text(params) do
    with changeset <- TextImport.changeset(%TextImport{}, params),
      {:ok, text_import} <- Ecto.Changeset.apply_action(changeset, :insert),
      response <- get_url(text_import.url),
      {:ok, text} <- build_text(%{ content: response.body }),
      {:ok, _} <- Cachex.put(@cache_name, text.id, text.content)
    do
      {:ok, text}
    else
      %HTTPotion.ErrorResponse{message: message} -> {:error, message}
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
end
