defmodule ComponentsGuideWeb.CalendarComponent do
  use ComponentsGuideWeb, :component

  def calendar_grid(assigns) do
    %{current_date: current_date} = assigns
    current_row_start_date = Date.beginning_of_week(current_date)
    current_day_of_week = Date.day_of_week(current_date)

    assigns =
      assigns
      |> Map.merge(%{
        current_row_start_date: current_row_start_date,
        current_day_of_week: current_day_of_week
      })
      |> Map.put_new(:extra, fn _ -> "" end)

    ~H"""
    <table class="text-center">
      <thead class="border-0">
        <tr>
          <th abbr="Monday">Mon</th>
          <th abbr="Tuesday">Tue</th>
          <th abbr="Wednesday">Wed</th>
          <th abbr="Thursday">Thu</th>
          <th abbr="Friday">Fri</th>
          <th abbr="Saturday">Sat</th>
          <th abbr="Sunday">Sun</th>
        </tr>
      </thead>
      <tbody>
      <%= for week_offset <- -4..4 do %>
        <tr class="min-h-16 group">
          <%= for weekday <- 1..7 do %>
            <% date = Date.add(@current_row_start_date, week_offset * 7 + (weekday - 1)) %>
            <% current_day? = week_offset == 0 && @current_day_of_week == weekday %>
            <td aria-current={if current_day?, do: "date", else: "false"} class={td_class(%{current_day?: current_day?, weekday: weekday, week_offset: week_offset})}>
              <div class={td_text_class(week_offset)}><%= Calendar.strftime(date, "%d %b") %></div>
              <%= @extra.(date) %>
            </td>
          <% end %>
        </tr>
      <% end %>
      </tbody>
    </table>
    """
  end

  defp td_class(%{current_day?: true}), do: "bg-green-900/90 text-green-100"
  defp td_class(%{weekday: weekday}) when weekday in [6, 7], do: "bg-black/40"
  defp td_class(%{week_offset: 0}), do: "bg-green-900/25"
  defp td_class(_), do: "bg-black"

  defp td_text_class(0), do: "text-sm opacity-100"
  defp td_text_class(week_offset) when week_offset in [-1, 1], do: "text-sm opacity-75"
  defp td_text_class(week_offset) when week_offset in [-2, 2], do: "text-sm opacity-60"
  defp td_text_class(_), do: "text-sm opacity-50"
end
