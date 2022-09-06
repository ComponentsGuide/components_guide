defmodule ComponentsGuideWeb.ResearchViewTest do
  use ComponentsGuideWeb.ConnCase, async: true

  alias ComponentsGuideWeb.ResearchView, as: Subject

  describe "humanize_bytes/1" do
    test "0" do
      assert Subject.humanize_bytes(0) == "0 B"
    end

    test "1" do
      assert Subject.humanize_bytes(1) == "1 B"
    end

    test "1023" do
      assert Subject.humanize_bytes(1023) == "1023 B"
    end

    test "1024" do
      assert Subject.humanize_bytes(1024) == "1.0 kB"
    end

    test "1025" do
      assert Subject.humanize_bytes(1025) == "1.0 kB"
    end

    test "1_000_000" do
      assert Subject.humanize_bytes(1_000_000) == "976.6 kB"
    end

    test "1_048_575" do
      assert Subject.humanize_bytes(1_048_575) == "1024.0 kB"
    end

    test "1_048_576" do
      assert Subject.humanize_bytes(1_048_576) == "1.0 mB"
    end
  end

  describe "humanize_count/1" do
    test "0" do
      assert Subject.humanize_count(0) == "0"
    end

    test "1" do
      assert Subject.humanize_count(1) == "1"
    end

    test "999" do
      assert Subject.humanize_count(999) == "999"
    end

    test "1000" do
      assert Subject.humanize_count(1000) == "1.0K"
    end

    test "10,000" do
      assert Subject.humanize_count(10_000) == "10.0K"
    end

    test "1,000,000" do
      assert Subject.humanize_count(1_000_000) == "1.0M"
    end
  end
end
