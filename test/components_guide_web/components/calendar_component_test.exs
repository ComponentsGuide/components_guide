defmodule ComponentsGuideWeb.CalendarComponentTest do
  # use ExUnit.Case
  # import Phoenix.LiveViewTest
  use ComponentsGuideWeb.ComponentCase
  alias ComponentsGuideWeb.CalendarComponent

  describe "CalendarComponent.calendar_grid" do
    setup context do
      assigns = context[:assigns]
      el = render_fragment(&CalendarComponent.calendar_grid/1, assigns)
      {:ok, el: el}
    end

    @tag assigns: [current_date: ~D[2022-04-01]]
    test "1st April 2022", %{el: el} do
      current_date = el |> find("td[aria-current=date]")
      assert "01 Apr" == current_date |> text() |> String.trim()
      assert current_date |> Enum.count() == 1

      assert 7 == count(el, "thead th")
      assert 9 == count(el, "tbody tr")
      assert 9 * 7 == count(el, "tbody td:not([role=presentation])")
    end

    @tag assigns: [current_date: ~D[2022-04-15]]
    test "15th April 2022", %{el: el} do
      current_date = el |> find("td[aria-current=date]")
      assert "15 Apr" == current_date |> text() |> String.trim()
    end

    @tag assigns: [current_date: ~D[2022-01-03]]
    test "3rd January 2022", %{el: el} do
      current_date = el |> find("td[aria-current=date]")
      assert "03 Jan" == current_date |> text() |> String.trim()
      assert 9 * 7 == count(el, "tbody td:not([role=presentation])")
    end
  end
end
