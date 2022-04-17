defmodule ComponentsGuideWeb.CalendarController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    nodejs_lts = %{
      nodejs12: %{lts_start: {2019, 10, 21}, end_of_life: {2022, 4, 30}},
      nodejs14: %{lts_start: {2021, 10, 27}, end_of_life: {2023, 4, 30}},
      nodejs16: %{lts_start: {2021, 10, 26}, maintenance_lts: {2022, 10, 18}, end_of_life: {2024, 4, 30}},
      nodejs18: %{release: {2022, 4, 19}, lts_start: {2022, 10, 25}, end_of_life: {2025, 4, 30}}
    }

    deno = %{
      deno1_20_0: %{release: {2022, 3, 16}},
      deno1_21_0: %{release: {2022, 4, 20}},
      deno1_22_0: %{release: {2022, 5, 18}}
    }

    react = %{
      react18: %{release: {2022, 3, 29}}
    }

    assigns = [
      current_week: iso_week_number(Date.utc_today() |> Date.to_erl()),
      deno1_20_0_week: week_diff(deno.deno1_20_0.release),
      deno1_21_0_week: week_diff(deno.deno1_21_0.release),
      deno1_22_0_week: week_diff(deno.deno1_22_0.release),
      nodejs18_release_week: week_diff(nodejs_lts.nodejs18.release),
      nodejs_lts_12_end_of_life_week: week_diff(nodejs_lts.nodejs12.end_of_life),
      nodejs_lts_16_maintenance_lts_week: week_diff(nodejs_lts.nodejs16.maintenance_lts),
      nodejs_lts_18_start_week: week_diff(nodejs_lts.nodejs18.lts_start),
      react18_week: week_diff(react.react18.release)
    ]

    render(conn, "index.html", assigns)
  end

  defp iso_week_number(date) do
    {_year, week_n} = :calendar.iso_week_number(date)
    week_n
  end

  defp week_diff(date) do
    current_week = iso_week_number(Date.utc_today() |> Date.to_erl())
    iso_week_number(date) - current_week
  end
end

defmodule ComponentsGuideWeb.CalendarView do
  use ComponentsGuideWeb, :view

  def released(assigns \\ []) do
    ~H"""
    <p><span class="text-3xl">🆕</span> <strong><%= @what %></strong> released <%= render_when(assigns.when) %></p>
    """
  end

  def end_of_life(assigns \\ []) do
    ~H"""
    <p><span class="text-3xl">🧟</span> <strong><%= @what %></strong> is end of life <%= render_when(assigns.when) %></p>
    """
  end

  def lts_starts(assigns \\ []) do
    ~H"""
    <p><span class="text-3xl">🦍</span> <strong><%= @what %></strong> made LTS <%= render_when(assigns.when) %></p>
    """
  end

  def hello(assigns \\ []) do
    ~H"""
    <p>Hello!</p>
    """
  end

  defp render_when(0), do: content_tag(:strong, "this week")
  defp render_when(1), do: content_tag(:strong, "next week")
  defp render_when(weeks_diff) when weeks_diff > 0, do: content_tag(:span, ["in ", content_tag(:strong, "#{weeks_diff} weeks")])
  defp render_when(weeks_diff), do: content_tag(:strong, "#{-weeks_diff} weeks ago")

  defp render_when_plain(0), do: "this week"
  defp render_when_plain(1), do: "next week"
  defp render_when_plain(weeks_diff) when weeks_diff > 0, do: "in #{weeks_diff} weeks"
  defp render_when_plain(weeks_diff), do: "#{-weeks_diff} weeks ago"
end
