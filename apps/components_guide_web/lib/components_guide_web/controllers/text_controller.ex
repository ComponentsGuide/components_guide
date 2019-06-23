defmodule ComponentsGuideWeb.TextController do
  use ComponentsGuideWeb, :controller

  alias ComponentsGuide.Content
  alias ComponentsGuide.Content.Text

  def index(conn, _params) do
    content = Content.list_content()
    import_changeset = Content.change_text(%Text{})
    render(conn, "index.html", content: content, import_changeset: import_changeset)
  end

  def new(conn, _params) do
    changeset = Content.change_text(%Text{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"text" => %{"url" => url}}) do
    case Content.import_text(%{"url" => url}) do
      {:ok, text} ->
        conn
        |> put_flash(:info, "Text imported successfully.")
        |> redirect(to: Routes.text_path(conn, :show, text))

      {:error, %Ecto.Changeset{} = import_changeset} ->
        render(conn, "index.html", content: [], import_changeset: import_changeset)
    end
  end

  def create(conn, %{"text" => text_params}) do
    case Content.create_text(text_params) do
      {:ok, text} ->
        conn
        |> put_flash(:info, "Text created successfully.")
        |> redirect(to: Routes.text_path(conn, :show, text))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    text = Content.get_text!(id)
    render(conn, "show.html", text: text)
  end

  def show_text_format(conn, %{"id" => id, "format" => format}) do
    text = Content.get_text!(id)
    conn
    |> put_resp_content_type("text/" <> format)
    |> send_resp(200, text.content)
  end

  def edit(conn, %{"id" => id}) do
    text = Content.get_text!(id)
    changeset = Content.change_text(text)
    render(conn, "edit.html", text: text, changeset: changeset)
  end

  def update(conn, %{"id" => id, "text" => text_params}) do
    text = Content.get_text!(id)

    case Content.create_text(text_params) do
      {:ok, text} ->
        conn
        |> put_flash(:info, "Text created successfully.")
        |> redirect(to: Routes.text_path(conn, :show, text))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", text: text, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _text} = Content.delete_text(id)

    conn
    |> put_flash(:info, "Text deleted successfully.")
    |> redirect(to: Routes.text_path(conn, :index))
  end
end
