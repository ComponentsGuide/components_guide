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

    @tag assigns: [year: 2022, month: 4]
    test "April 2022", a do
      %{el: el} = a
      current_date = el |> find("td[aria-current=date]")
      assert current_date |> Enum.count() == 0

      assert 7 == count(el, "thead th")
      assert 5 == count(el, "tbody tr")
      assert 30 == count(el, "tbody td:not([role=presentation])")
    end

    @tag assigns: [year: 2022, month: 4, current_date: ~D[2022-04-01]]
    test "April 2022 with 1st as current date", a do
      %{el: el} = a
      current_date = el |> find("td[aria-current=date]")
      assert "1" == current_date |> text() |> String.trim()
      assert current_date |> Enum.count() == 1

      assert 7 == count(el, "thead th")
      assert 5 == count(el, "tbody tr")
      assert 30 == count(el, "tbody td:not([role=presentation])")
    end

    @tag assigns: [year: 2022, month: 4, current_date: ~D[2022-04-15]]
    test "April 2022 with 15th as current date", %{el: el} do
      current_date = el |> find("td[aria-current=date]")
      assert "15" == current_date |> text() |> String.trim()
    end

    @tag assigns: [year: 2022, month: 1, current_date: ~D[2022-01-03]]
    test "January 2022 with 3rd as current date", %{el: el} do
      current_date = el |> find("td[aria-current=date]")
      assert "3" == current_date |> text() |> String.trim()
      assert 31 == count(el, "tbody td:not([role=presentation])")
    end
  end
end
