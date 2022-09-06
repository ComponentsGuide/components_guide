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
      deno1_22: %{release: {2022, 5, 18}},
      deno1_23: %{release: {2022, 6, 16}},
      deno1_24: %{release: {2022, 7, 21}},
      deno1_25: %{release: {2022, 8, 25}}
    }

    react = %{
      react18: %{release: {2022, 3, 29}},
      react_query4: %{release: {2022, 7, 18}}
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

    rust = %{
      rust1_62: %{release: {2022, 6, 30}}
    }

    browsers = %{
      firefox99: %{release: {2022, 4, 5}},
      firefox100: %{release: {2022, 5, 3}},
      firefox101: %{release: {2022, 5, 31}},
      firefox102: %{release: {2022, 6, 28}},
      firefox103: %{release: {2022, 7, 26}},
      chrome99: %{release: {2022, 3, 1}},
      chrome100: %{release: {2022, 3, 29}},
      chrome101: %{release: {2022, 4, 26}},
      chrome102: %{release: {2022, 5, 24}},
      chrome103: %{release: {2022, 6, 21}},
      chrome104: %{release: {2022, 8, 2}},
      chrome105: %{release: {2022, 8, 30}},
      chrome106: %{release: {2022, 9, 27}},
      safari15_4: %{release: {2022, 3, 14}},
      safari15_5: %{release: {2022, 5, 16}},
      safari15_6: %{release: {2022, 7, 20}}
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
      rust,
      browsers,
      postgres,
      aws_lambda,
      jest
    ]

    links = %{
      chrome99: "https://developer.chrome.com/blog/new-in-chrome-99/",
      chrome100: "https://developer.chrome.com/blog/new-in-chrome-100/",
      chrome101: "https://developer.chrome.com/blog/new-in-chrome-101/",
      chrome102: "https://developer.chrome.com/blog/new-in-chrome-102/",
      chrome103: "https://developer.chrome.com/blog/new-in-chrome-103/",
      chrome104: "https://developer.chrome.com/blog/new-in-chrome-104/",
      deno1_20: "https://deno.com/blog/v1.20",
      deno1_21: "https://deno.com/blog/v1.21",
      deno1_22: "https://deno.com/blog/v1.22",
      deno1_23: "https://deno.com/blog/v1.23",
      deno1_24: "https://deno.com/blog/v1.24",
      deno1_25: "https://deno.com/blog/v1.25",
      react18: "https://reactjs.org/blog/2022/03/29/react-v18.html",
      react_query4: "https://tanstack.com/blog/announcing-tanstack-query-v4",
      firefox99: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/99",
      firefox100: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/100",
      firefox101: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/101",
      firefox102: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/102",
      firefox103: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/103",
      swift5_6: "https://www.swift.org/blog/swift-5.6-released/",
      safari15_4: "https://webkit.org/blog/12445/new-webkit-features-in-safari-15-4/",
      safari15_5: "https://webkit.org/blog/12669/new-webkit-features-in-safari-15-5/",
      safari15_6: "https://webkit.org/blog/13009/new-webkit-features-in-safari-15-6/",
      go1_18: "https://go.dev/doc/go1.18",
      rust1_62: "https://blog.rust-lang.org/2022/06/30/Rust-1.62.0.html",
      nodejs18: "https://nodejs.org/en/blog/announcements/v18-release-announce/",
      jest28: "https://jestjs.io/blog/2022/04/25/jest-28"
    }

    dates_to_items =
      for group <- groups do
        for {id, %{release: yymmdd}} <- group do
          {yymmdd, id}
        end
      end
      |> List.flatten()
      |> Enum.group_by(fn {k, _} -> k end, fn {_, v} -> v end)
      |> Map.new()

    today = Date.utc_today()

    calendar_extra = fn date ->
      yymmdd = Date.to_erl(date)

      ids = Map.get(dates_to_items, yymmdd, [])
      ComponentsGuideWeb.CalendarView.icon_links(ids, links)

      # case Map.get(dates_to_items, yymmdd) do
      #   nil ->
      #     ""

      #   ids ->
      #     for id <- ids do
      #       ComponentsGuideWeb.CalendarView.icon_link(id)
      #     end
      # end
    end

    assigns = [
      page_title:
        "Calendar of when important tools are released, become LTS, and reach end-of-life",
      today: today,
      current_week: today |> Date.to_erl() |> iso_week_number(),
      list: create_list(groups, links),
      calendar_extra: calendar_extra
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
      {type, x} when type in [:end_of_life, :deprecation_phase_2] and x in -400..400 -> true
      {_, x} when x in -50..300 -> true
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

  def icon_link(id, link) do
    assigns = %{
      what: pretty_name(id),
      href: link || "#",
      icon: pretty_icon(id)
    }

    ~H"""
    <a href={@href}>
      <span class="text-3xl not-prose"><%= @icon %></span>
      <%= @what %>
    </a>
    """
  end

  def icon_links(ids, links) do
    assigns = %{ids: ids}

    ~H"""
    <%= for id <- @ids do %>
    <%= ComponentsGuideWeb.CalendarView.icon_link(id, Map.get(links, id)) %>
    <% end %>
    """
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
      <<"rust" <> version>> -> "Rust #{pretty_version(version)}"
      <<"react_query" <> version>> -> "React Query #{pretty_version(version)}"
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
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/postgresql.svg"

        <<"swift" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/swift.svg"

        <<"go" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/go.svg"

        <<"rust" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v7/icons/rust.svg"

        <<"react_query" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v7/icons/reactquery.svg"

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
