defmodule ComponentsGuideWeb.CalendarComponent do
  use ComponentsGuideWeb, :component

  def calendar_grid(assigns) do
    %{year: year, month: month, day: day} = today = assigns[:date]
    start_date = Date.beginning_of_month(today)
    end_date = Date.end_of_month(today)
    date_range = Date.range(start_date, end_date)

    day_inset = Date.day_of_week(start_date)
    day_offset = 1 - day_inset
    max_week = div(end_date.day + day_inset + 5, 7)

    assigns =
      assigns
      |> Map.merge(%{
        date_range: date_range,
        year: year,
        month: month,
        day: day,
        day_offset: day_offset
      })

    ~H"""
    <h2><%= Calendar.strftime(@date_range.first, "%B %Y") %></h2>
    <table class="text-center">
      <thead>
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
      <%= for week_n <- 1..max_week do %>
        <tr>
          <%= for day_n <- 1..7 do %>
            <% day = day_n + day_offset + ((week_n - 1) * 7) %>
            <%= if day in @date_range.first.day..@date_range.last.day do %>
              <% current = day == @day %>
              <td aria-current={if current, do: "date", else: "false"} class={if current, do: "bg-red-900", else: "bg-black"}>
                <%= day %>
              </td>
            <% else %>
              <td role="presentation" class=""></td>
            <% end %>
          <% end %>
        </tr>
      <% end %>
      </tbody>
    </table>
    """
  end
end