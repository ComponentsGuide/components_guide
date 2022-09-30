defmodule ComponentsGuideWeb.CalendarComponent do
  use ComponentsGuideWeb, :component

  def calendar_grid(assigns) do
    %{year: year, month: month} = assigns

    day =
      case assigns[:current_date] do
        nil ->
          nil

        %{day: day} ->
          day
      end

    # %{year: year, month: month, day: day} = today = assigns[:date]
    date = Date.new!(year, month, 1)
    start_date = Date.beginning_of_month(date)
    end_date = Date.end_of_month(date)
    date_range = Date.range(start_date, end_date)

    day_of_week = Date.day_of_week(start_date)
    day_offset = 1 - day_of_week
    max_week = div(end_date.day + day_of_week + 5, 7)

    assigns =
      assigns
      |> Map.merge(%{
        date_range: date_range,
        year: year,
        month: month,
        day: day,
        current: Date.new!(year, month, day),
        day_of_week: day_of_week,
        day_offset: day_offset
      })
      |> Map.put_new(:extra, fn _ -> "" end)

    ~H"""
    <%= if false do %>
      <h2 class="text-center"><%= Calendar.strftime(@date_range.first, "%B %Y") %></h2>
    <% end %>
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
      <%= for week_n <- 1..max_week, false do %>
        <tr class="min-h-16">
          <%= for weekday <- 0..6 do %>
            <% day = weekday + 1 + day_offset + ((week_n - 1) * 7) %>
            <%= if day in @date_range.first.day..@date_range.last.day do %>
              <% current? = day == @day %>
              <td aria-current={if current?, do: "date", else: "false"} class={td_class(%{current?: current?, weekday: weekday})}>
                <div class="text-sm"><%= day %></div>
                <%= @extra.(Date.new!(year, month, day)) %>
              </td>
            <% else %>
              <td role="presentation" class=""></td>
            <% end %>
          <% end %>
        </tr>
      <% end %>
      <%= for week_offset <- -4..4 do %>
        <tr class="min-h-16 group">
          <%= for weekday <- 0..6 do %>
            <% date = Date.add(@current, (week_offset - 1) * 7 + weekday - day_offset) %>
            <% current? = week_offset == 0 && day_of_week == weekday %>
            <td aria-current={if current?, do: "date", else: "false"} class={td_class(%{current?: current?, weekday: weekday})}>
              <div class={cell_text_class(week_offset)}><%= Calendar.strftime(date, "%d %b") %></div>
              <%= @extra.(date) %>
            </td>
          <% end %>
        </tr>
      <% end %>
      </tbody>
    </table>
    """
  end

  defp td_class(%{current?: true}), do: "bg-green-900 text-green-100"
  defp td_class(%{weekday: weekday}) when weekday in [5, 6], do: "bg-black/40"
  defp td_class(_), do: "bg-black"

  defp cell_text_class(0), do: "text-sm opacity-100"
  defp cell_text_class(week_offset) when week_offset in [-1, 1], do: "text-sm opacity-75"
  defp cell_text_class(week_offset) when week_offset in [-2, 2], do: "text-sm opacity-60"
  defp cell_text_class(_), do: "text-sm opacity-50"
end
