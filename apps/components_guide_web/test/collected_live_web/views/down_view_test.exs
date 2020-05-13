defmodule ComponentsGuideWeb.DownViewTest do
  use ComponentsGuideWeb.ConnCase, async: true

  alias ComponentsGuideWeb.DownView, as: Subject
  use Phoenix.HTML

  describe "humanize_bytes/1" do
    test "plain text" do
      assert Subject.down("plain text") == raw("plain text")
    end

    test "italics" do
      assert Subject.down("plain _text_") == raw("plain <em>text</em>")
    end
  end
end
