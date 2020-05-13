defmodule ComponentsGuideWeb.DownViewTest do
  use ComponentsGuideWeb.ConnCase, async: true

  alias ComponentsGuideWeb.DownView, as: Subject
  use Phoenix.HTML

  describe "humanize_bytes/1" do
    test "plain text" do
      assert Subject.down("plain text") == raw("plain text")
    end

    test "italics with _" do
      assert Subject.down("text _italics_ normal") == raw("text <em>italics</em> normal")
    end

    test "italics with *" do
      assert Subject.down("text *italics* normal") == raw("text <em>italics</em> normal")
    end

    test "bold with **" do
      assert Subject.down("text **bold** normal") == raw("text <strong>bold</strong> normal")
    end

    test "link with inline url" do
      assert Subject.down("text with [link](https://example.org/) somewhere") ==
               raw("text with <a href=\"https://example.org/\">link</a> somewhere")
    end
  end
end
