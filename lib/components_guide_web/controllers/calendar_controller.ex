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

    jest = %{
      jest28: %{release: {2022, 4, 25}}
    }

    postgres = %{
      postgres9_6: %{end_of_life: {2021, 11, 11}},
      postgres10: %{end_of_life: {2022, 11, 10}}
    }

    swift = %{
      swift5_6: %{release: {2022, 3, 14}}
    }

    golang = %{
      go1_18: %{release: {2022, 3, 15}}
    }

    browsers = %{
      firefox99: %{release: {2022, 4, 5}},
      firefox100: %{release: {2022, 5, 3}},
      firefox101: %{release: {2022, 5, 31}},
      firefox102: %{release: {2022, 6, 28}},
      chrome99: %{release: {2022, 3, 1}},
      chrome100: %{release: {2022, 3, 29}},
      chrome101: %{release: {2022, 4, 26}},
      chrome102: %{release: {2022, 5, 24}},
      chrome103: %{release: {2022, 6, 21}},
      safari15_4: %{release: {2022, 3, 14}}
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
      swift,
      golang,
      browsers,
      postgres,
      aws_lambda,
      jest
    ]

    links = %{
      chrome99: "https://developer.chrome.com/blog/new-in-chrome-99/",
      chrome100: "https://developer.chrome.com/blog/new-in-chrome-100/",
      deno1_20: "https://deno.com/blog/v1.20",
      react18: "https://reactjs.org/blog/2022/03/29/react-v18.html",
      firefox99: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/99",
      swift5_6: "https://www.swift.org/blog/swift-5.6-released/",
      safari15_4: "https://webkit.org/blog/12445/new-webkit-features-in-safari-15-4/",
      go1_18: "https://go.dev/doc/go1.18",
      nodejs18: "https://nodejs.org/en/blog/announcements/v18-release-announce/",
      deno1_21: "https://deno.com/blog/v1.21",
      jest28: "https://jestjs.io/blog/2022/04/25/jest-28"
    }

    today = Date.utc_today()

    assigns = [
      page_title:
        "Calendar of when important tools are released, become LTS, and reach end-of-life",
      today: today,
      current_week: today |> Date.to_erl() |> iso_week_number(),
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

  alias ComponentsGuideWeb.CalendarComponent

  def present_item({id, {date, type, meta}}) do
    options = %{
      what: pretty_name(id),
      date: date,
      href: meta[:link],
      icon: pretty_icon(id)
    }

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
      <<"safari" <> version>> -> "Safari #{pretty_version(version)}"
      <<"postgres" <> version>> -> "Postgres #{pretty_version(version)}"
      <<"swift" <> version>> -> "Swift #{pretty_version(version)}"
      <<"go" <> version>> -> "Go #{pretty_version(version)}"
      <<"react" <> version>> -> "React #{pretty_version(version)}"
      <<"jest" <> version>> -> "Jest #{pretty_version(version)}"
      <<"aws_lambda_nodejs" <> version>> -> "AWS Lambda Node.js #{pretty_version(version)}"
      s -> s
    end
  end

  defp pretty_version(v_string) do
    v_string |> String.replace("_", ".")
  end

  defp pretty_icon(id) do
    url =
      case Atom.to_string(id) do
        <<"nodejs" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/nodedotjs.svg"

        <<"deno" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/deno.svg"

        <<"firefox" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/firefox.svg"

        <<"chrome" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/googlechrome.svg"

        <<"safari" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/safari.svg"

        <<"postgres" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/postgres.svg"

        <<"swift" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/swift.svg"

        <<"go" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/go.svg"

        <<"react" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/react.svg"

        <<"jest" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/jest.svg"

        <<"aws_lambda_nodejs" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/awslambda.svg"

        _ ->
          nil
      end

    case url do
      nil ->
        nil

      url ->
        tag(:img,
          src: url,
          width: 32,
          height: 32,
          role: "presentation",
          class: "inline-block align-middle invert mr-[2px]"
        )
    end
  end

  def released(assigns \\ []) do
    ~H"""
    <p data-type="released">
      <span class="text-3xl not-prose"><%= @icon || "🆕" %></span>
      <%= if assigns[:href] do %>
      <a href={@href} class="font-bold"><%= @what %></a>
      <% else %>
      <strong><%= @what %></strong>
      <% end %>
      released
      <%= render_when(assigns.date) %>
    </p>
    """
  end

  def end_of_life(assigns \\ []) do
    ~H"""
    <p data-type="end_of_life">
      <span class="text-3xl">🧟</span>
      <strong><%= @what %></strong>
      end of life
      <%= render_when(assigns.date, "text-red-400") %>
    </p>
    """
  end

  def lts_starts(assigns \\ []) do
    ~H"""
    <p data-type="lts_starts">
      <span class="text-3xl">🦍</span>
      <strong><%= @what %></strong>
      made LTS
      <%= render_when(assigns.date) %>
    </p>
    """
  end

  defp render_when(date_tuple, class \\ nil) do
    datetime = date_tuple |> Date.from_erl!() |> Date.to_iso8601()
    weeks = week_diff(date_tuple)

    {prefix, text} =
      case weeks do
        0 -> {"", "this week"}
        1 -> {"", "next week"}
        -1 -> {"", "last week"}
        x when x > 0 -> {"in ", "#{x} weeks"}
        x when x < 0 -> {"", "#{-x} weeks ago"}
      end

    class =
      case {class, weeks} do
        {class, _} when not is_nil(class) -> class
        {_, 0} -> "text-green-300"
        {_, x} when x > 0 -> "text-orange-300"
        {_, x} when x < 0 -> "text-blue-300"
      end

    content_tag(:span, [
      prefix,
      content_tag(:time, text, datetime: datetime, title: datetime, class: "font-bold #{class}")
    ])
  end
end
