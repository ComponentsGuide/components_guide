defmodule ComponentsGuideWeb.CalendarController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    nodejs_lts = %{
      nodejs12: %{lts_start: {2019, 10, 21}, end_of_life: {2022, 4, 30}},
      nodejs14: %{lts_start: {2021, 10, 27}, end_of_life: {2023, 4, 30}},
      nodejs16: %{
        lts_start: {2021, 10, 26},
        maintenance_lts: {2022, 10, 18},
        end_of_life: {2024, 4, 30}
      },
      nodejs18: %{release: {2022, 4, 19}, lts_start: {2022, 10, 25}, end_of_life: {2025, 4, 30}}
    }

    deno = %{
      deno1_20: %{release: {2022, 3, 16}},
      deno1_21: %{release: {2022, 4, 20}},
      deno1_22: %{release: {2022, 5, 18}}
    }

    react = %{
      react18: %{release: {2022, 3, 29}}
    }

    postgres = %{
      postgres9_6: %{end_of_life: {2021, 11, 11}},
      postgres10: %{end_of_life: {2022, 11, 10}}
    }

    browsers = %{
      firefox99: %{release: {2022, 4, 5}},
      chrome99: %{release: {2022, 3, 1}},
      chrome100: %{release: {2022, 3, 29}},
      chrome101: %{release: {2022, 4, 26}},
      chrome102: %{release: {2022, 5, 24}}
    }

    aws_lambda = %{
      aws_lambda_nodejs10: %{
        deprecation_phase_1: {2021, 7, 30},
        deprecation_phase_2: {2022, 2, 14}
      }
    }

    groups = [
      nodejs_lts,
      deno,
      react,
      browsers,
      postgres,
      aws_lambda
    ]

    links = %{
      chrome99: "https://developer.chrome.com/blog/new-in-chrome-99/",
      chrome100: "https://developer.chrome.com/blog/new-in-chrome-100/",
      deno1_20: "https://deno.com/blog/v1.20",
      react18: "https://reactjs.org/blog/2022/03/29/react-v18.html",
      firefox99: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/99"
    }

    assigns = [
      current_week: iso_week_number(Date.utc_today() |> Date.to_erl()),
      deno1_20_week: week_diff(deno.deno1_20.release),
      deno1_21_week: week_diff(deno.deno1_21.release),
      deno1_22_week: week_diff(deno.deno1_22.release),
      nodejs18_release_week: week_diff(nodejs_lts.nodejs18.release),
      nodejs_lts_12_end_of_life_week: week_diff(nodejs_lts.nodejs12.end_of_life),
      nodejs_lts_16_maintenance_lts_week: week_diff(nodejs_lts.nodejs16.maintenance_lts),
      nodejs_lts_18_start_week: week_diff(nodejs_lts.nodejs18.lts_start),
      react18_week: week_diff(react.react18.release),
      postgres9_6_end_of_life_week: week_diff(postgres.postgres9_6.end_of_life),
      postgres10_end_of_life_week: week_diff(postgres.postgres10.end_of_life),
      firefox99_week: week_diff(browsers.firefox99.release),
      chrome99_week: week_diff(browsers.chrome99.release),
      chrome100_week: week_diff(browsers.chrome100.release),
      chrome101_week: week_diff(browsers.chrome101.release),
      aws_lambda_nodejs10_deprecated_week:
        week_diff(aws_lambda.aws_lambda_nodejs10.deprecation_phase_2),
      list: create_list(groups, links)
    ]

    render(conn, "index.html", assigns)
  end

  defp create_list(groups, links) do
    today = Date.utc_today()

    items =
      for group <- groups,
          {id, dates} <- group,
          {type, date} <- dates do
        {id, {date, type}}
      end

    items
    |> Enum.filter(&include_date?(&1, today))
    |> Enum.sort_by(fn {key, value} -> {value, key} end, :asc)
    |> Enum.map(fn {key, {date, type}} ->
      {key,
       {date, type,
        case {type, links} do
          {:release, %{^key => link}} -> %{link: link}
          _ -> %{}
        end}}
    end)
  end

  defp include_date?({_, {date, type}}, today) do
    case {type, Date.diff(Date.from_erl!(date), today)} do
      {:end_of_life, x} when x in -400..400 -> true
      {_, x} when x in -100..300 -> true
      _ -> false
    end
  end

  defp iso_week_number(date) do
    {_year, week_n} = :calendar.iso_week_number(date)
    week_n
  end

  defp week_diff(date) do
    today = Date.utc_today()
    {current_year, current_week} = :calendar.iso_week_number(Date.to_erl(today))
    {target_year, target_week} = :calendar.iso_week_number(date)

    if target_year == current_year do
      target_week - current_week
    else
      days_diff = Date.diff(Date.from_erl!(date), today)
      # Integer.floor_div(days_diff, 7)
      div(days_diff, 7)
    end
  end
end

defmodule ComponentsGuideWeb.CalendarView do
  use ComponentsGuideWeb, :view

  def present_item({id, {date, type, meta}}) do
    options = %{what: pretty_name(id), when: week_diff(date), href: meta[:link]}

    case type do
      :release -> released(options)
      :end_of_life -> end_of_life(options)
      :deprecation_phase_2 -> end_of_life(options)
      :lts_start -> lts_starts(options)
      _ -> ""
    end
  end

  defp week_diff(date) do
    today = Date.utc_today()
    {current_year, current_week} = :calendar.iso_week_number(Date.to_erl(today))
    {target_year, target_week} = :calendar.iso_week_number(date)

    if target_year == current_year do
      target_week - current_week
    else
      days_diff = Date.diff(Date.from_erl!(date), today)
      # Integer.floor_div(days_diff, 7)
      div(days_diff, 7)
    end
  end

  defp pretty_name(id) do
    case Atom.to_string(id) do
      <<"nodejs" <> version>> -> "Node.js #{pretty_version(version)}"
      <<"deno" <> version>> -> "Deno #{pretty_version(version)}"
      <<"firefox" <> version>> -> "Firefox #{pretty_version(version)}"
      <<"chrome" <> version>> -> "Chrome #{pretty_version(version)}"
      <<"postgres" <> version>> -> "Postgres #{pretty_version(version)}"
      <<"react" <> version>> -> "React #{pretty_version(version)}"
      <<"aws_lambda_nodejs" <> version>> -> "AWS Lambda Node.js #{pretty_version(version)}"
      s -> s
    end
  end

  defp pretty_version(v_string) do
    v_string |> String.replace("_", ".")
  end

  def released(assigns \\ []) do
    ~H"""
    <p data-type="released">
      <span class="text-3xl">🆕</span>
      <%= if assigns[:href] do %>
      <a href={@href} class="font-bold"><%= @what %></a>
      <% else %>
      <strong><%= @what %></strong>
      <% end %>
      released
      <%= render_when(assigns.when, nil) %>
    </p>
    """
  end

  def end_of_life(assigns \\ []) do
    ~H"""
    <p data-type="end_of_life">
      <span class="text-3xl">🧟</span>
      <strong><%= @what %></strong>
      end of life
      <%= render_when(assigns.when, "text-red-400") %>
    </p>
    """
  end

  def lts_starts(assigns \\ []) do
    ~H"""
    <p data-type="lts_starts">
      <span class="text-3xl">🦍</span>
      <strong><%= @what %></strong>
      made LTS
      <%= render_when(assigns.when, nil) %>
    </p>
    """
  end

  # defp render_when(0), do: content_tag(:strong, "0W", class: "text-green-300")
  # defp render_when(weeks_diff) when weeks_diff > 0, do: content_tag(:strong, "+#{weeks_diff}W", class: "text-orange-300")
  # defp render_when(weeks_diff), do: content_tag(:strong, "#{weeks_diff}W", class: "text-blue-300")

  defp render_when(0, class),
    do: content_tag(:strong, "this week", class: class || "text-green-300")

  defp render_when(1, class),
    do: content_tag(:strong, "next week", class: class || "text-orange-300")

  defp render_when(-1, class),
    do: content_tag(:strong, "1 week ago", class: class || "text-blue-300")

  defp render_when(weeks_diff, class) when weeks_diff > 0,
    do:
      content_tag(:span, [
        "in ",
        content_tag(:strong, "#{weeks_diff} weeks", class: class || "text-orange-300")
      ])

  defp render_when(weeks_diff, class),
    do: content_tag(:strong, "#{-weeks_diff} weeks ago", class: class || "text-blue-300")

  # defp render_when_plain(0), do: "this week"
  # defp render_when_plain(1), do: "next week"
  # defp render_when_plain(weeks_diff) when weeks_diff > 0, do: "in #{weeks_diff} weeks"
  # defp render_when_plain(weeks_diff), do: "#{-weeks_diff} weeks ago"
end
