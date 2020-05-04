defmodule ComponentsGuideWeb.ResearchViewTest do
  use ComponentsGuideWeb.ConnCase, async: true

  alias ComponentsGuideWeb.ResearchView, as: Subject

  describe "humanize_bytes/1" do
    defp subject(count) do
      Subject.humanize_bytes(count)
    end

    test "0" do
      assert subject(0) == "0 B"
    end

    test "1" do
      assert subject(1) == "1 B"
    end

    test "1023" do
      assert subject(1023) == "1023 B"
    end

    test "1024" do
      assert subject(1024) == "1.0 kB"
    end

    test "1025" do
      assert subject(1025) == "1.0 kB"
    end

    test "1_000_000" do
      assert subject(1_000_000) == "976.6 kB"
    end

    test "1_048_575" do
      assert subject(1_048_575) == "1024.0 kB"
    end

    test "1_048_576" do
      assert subject(1_048_576) == "1.0 mB"
    end
  end
end
