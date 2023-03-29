defmodule ComponentsGuideWeb.DevCalendarComponent do
  use ComponentsGuideWeb, :component

  alias ComponentsGuideWeb.CalendarComponent

  def calendar(assigns \\ %{}) do
    today = Date.utc_today()
    %{dates_to_items: dates_to_items, links: links} = get_data()

    assigns = %{
      today: today,
      dates_to_items: dates_to_items,
      links: links
    }

    ~H"""
    <CalendarComponent.calendar_grid current_date={@today}>
      <:cell_content :let={date}>
        <.date_links date={date} dates_to_items={@dates_to_items} links={@links} />
      </:cell_content>
    </CalendarComponent.calendar_grid>
    """
  end

  def list(assigns \\ %{}) do
    %{groups: groups, links: links} = get_data()
    list = create_list(groups, links)

    assigns = %{list: list}

    ~H"""
    <article>
      <h2>All releases</h2>
      <form id="filter-calendar" class="flex flex-wrap gap-6 -mt-8 mb-8 select-none">
        <label><input type="checkbox" name="end_of_life" checked class="rounded text-sky-500"> End of life</label>
        <label><input type="checkbox" name="released" checked class="rounded text-sky-500"> Released</label>
        <label><input type="checkbox" name="lts_starts" checked class="rounded text-sky-500"> LTS</label>
      </form>
      <%= for item <- @list do %>
      <%= present_item(item) %>
      <% end %>
    </article>

    <script type="module">
      const form = document.getElementById("filter-calendar");
      const items = form.parentNode.querySelectorAll('article p');
      form.addEventListener('change', () => {
        const values = new FormData(form);
        const enabledTypes = new Set(values.keys());
        for (const item of Array.from(items)) {
          const matches = enabledTypes.has(item.dataset.type);
          item.hidden = !matches;
        }
      });
    </script>
    """
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

  defp date_links(assigns) do
    yymmdd = Date.to_erl(assigns.date)

    ids = Map.get(assigns.dates_to_items, yymmdd, [])
    icon_links(ids, assigns.links)
  end

  defp icon_links(ids, links) do
    assigns = %{ids: ids, links: links}

    ~H"""
    <div class="flex flex-col gap-2">
      <%= for id <- @ids do %>
      <div>
      <%= icon_link(id, Map.get(@links, id)) %>
      </div>
      <% end %>
    </div>
    """
  end

  defp icon_link(id, link) do
    assigns = %{
      what: pretty_name(id),
      href: link || "#",
      icon: pretty_icon(id)
    }

    ~H"""
    <a href={@href} class="flex flex-col md:block">
      <span class="text-3xl not-prose"><%= @icon %></span>
      <%= @what %>
    </a>
    """
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
      <<"elixir" <> version>> -> "Elixir #{pretty_version(version)}"
      <<"go" <> version>> -> "Go #{pretty_version(version)}"
      <<"rust" <> version>> -> "Rust #{pretty_version(version)}"
      <<"react_query" <> version>> -> "React Query #{pretty_version(version)}"
      <<"react" <> version>> -> "React #{pretty_version(version)}"
      <<"remix" <> version>> -> "Remix #{pretty_version(version)}"
      <<"jest" <> version>> -> "Jest #{pretty_version(version)}"
      <<"aws_lambda_nodejs" <> version>> -> "AWS Lambda Node.js #{pretty_version(version)}"
      <<"ios" <> version>> -> "iOS #{pretty_version(version)}"
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

        <<"nextjs" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v7/icons/nextdotjs.svg"

        <<"react" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/react.svg"

        <<"remix" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v7/icons/remix.svg"

        <<"jest" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/jest.svg"

        <<"elixir" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v7/icons/elixir.svg"

        <<"aws_lambda_nodejs" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v6/icons/awslambda.svg"

        <<"ios" <> _>> ->
          "https://cdn.jsdelivr.net/npm/simple-icons@v7/icons/ios.svg"

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
      starts LTS
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

  def get_data() do
    nodejs_lts = %{
      nodejs12: %{lts_start: {2019, 10, 21}, end_of_life: {2022, 4, 30}},
      nodejs14: %{lts_start: {2021, 10, 27}, end_of_life: {2023, 4, 30}},
      nodejs16: %{
        lts_start: {2021, 10, 26},
        maintenance_lts: {2022, 10, 18},
        end_of_life: {2024, 4, 30}
      },
      nodejs18: %{release: {2022, 4, 19}, lts_start: {2022, 10, 25}, end_of_life: {2025, 4, 30}},
      nodejs20: %{release: {2023, 4, 18}, lts_start: {2023, 10, 24}, end_of_life: {2026, 4, 30}}
    }

    deno = %{
      deno1_20: %{release: {2022, 3, 16}},
      deno1_21: %{release: {2022, 4, 20}},
      deno1_22: %{release: {2022, 5, 18}},
      deno1_23: %{release: {2022, 6, 16}},
      deno1_24: %{release: {2022, 7, 21}},
      deno1_25: %{release: {2022, 8, 25}},
      deno1_26: %{release: {2022, 9, 29}},
      deno1_27: %{release: {2022, 10, 27}},
      deno1_28: %{release: {2022, 11, 14}},
      deno1_29: %{release: {2022, 12, 14}},
      deno1_30: %{release: {2023, 1, 27}},
      deno1_31: %{release: {2023, 2, 24}},
      deno1_32: %{release: {2023, 3, 23}},
    }

    react = %{
      react18: %{release: {2022, 3, 29}},
      react_query4: %{release: {2022, 7, 18}},
      nextjs13: %{release: {2022, 10, 26}},
      nextjs13_1: %{release: {2022, 12, 23}},
      remix1_11: %{release: {2023, 1, 19}},
      remix1_12: %{release: {2023, 1, 31}}
    }

    jest = %{
      jest28: %{release: {2022, 4, 25}},
      jest29: %{release: {2022, 8, 25}},
    }

    postgres = %{
      postgres9_6: %{end_of_life: {2021, 11, 11}},
      postgres10: %{end_of_life: {2022, 11, 10}}
    }

    erlang = %{
      elixir1_14: %{release: {2022, 9, 1}},
    }

    swift = %{
      swift5_6: %{release: {2022, 3, 14}},
      swift5_7: %{release: {2022, 9, 12}}
    }

    golang = %{
      go1_18: %{release: {2022, 3, 15}},
      go1_19: %{release: {2022, 8, 2}},
      go1_20: %{release: {2023, 2, 1}},
    }

    rust = %{
      rust1_62: %{release: {2022, 6, 30}},
      rust1_63: %{release: {2022, 8, 11}},
      rust1_64: %{release: {2022, 9, 22}},
      rust1_65: %{release: {2022, 11, 3}},
      rust1_66: %{release: {2022, 12, 15}}
    }

    browsers = %{
      firefox99: %{release: {2022, 4, 5}},
      firefox100: %{release: {2022, 5, 3}},
      firefox101: %{release: {2022, 5, 31}},
      firefox102: %{release: {2022, 6, 28}},
      firefox103: %{release: {2022, 7, 26}},
      firefox104: %{release: {2022, 8, 23}},
      firefox105: %{release: {2022, 9, 20}},
      firefox106: %{release: {2022, 10, 18}},
      firefox107: %{release: {2022, 11, 15}},
      firefox108: %{release: {2022, 12, 13}},
      firefox109: %{release: {2023, 1, 17}},
      firefox110: %{release: {2023, 2, 14}},
      firefox111: %{release: {2023, 3, 14}},
      firefox112: %{release: {2023, 4, 11}},
      firefox113: %{release: {2023, 5, 9}},
      firefox114: %{release: {2023, 6, 6}},
      chrome99: %{release: {2022, 3, 1}},
      chrome100: %{release: {2022, 3, 29}},
      chrome101: %{release: {2022, 4, 26}},
      chrome102: %{release: {2022, 5, 24}},
      chrome103: %{release: {2022, 6, 21}},
      chrome104: %{release: {2022, 8, 2}},
      chrome105: %{release: {2022, 8, 30}},
      chrome106: %{release: {2022, 9, 27}},
      chrome107: %{release: {2022, 10, 27}},
      chrome108: %{release: {2022, 12, 1}},
      chrome109: %{release: {2023, 1, 10}},
      chrome110: %{release: {2023, 2, 7}},
      chrome111: %{release: {2023, 3, 7}},
      chrome112: %{release: {2023, 4, 4}},
      chrome113: %{release: {2023, 5, 2}},
      chrome114: %{release: {2023, 5, 30}},
      chrome115: %{release: {2023, 6, 27}},
      safari15_4: %{release: {2022, 3, 14}},
      safari15_5: %{release: {2022, 5, 16}},
      safari15_6: %{release: {2022, 7, 20}},
      safari16: %{release: {2022, 9, 12}},
      safari16_1: %{release: {2022, 10, 24}},
      safari16_2: %{release: {2022, 12, 13}}
    }

    ios = %{
      ios16: %{release: {2022, 9, 12}}
    }

    aws_lambda = %{
      aws_lambda_nodejs10: %{
        deprecation_phase_1: {2021, 7, 30},
        deprecation_phase_2: {2022, 2, 14}
      }
    }

    groups = [
      ios,
      nodejs_lts,
      deno,
      react,
      swift,
      erlang,
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
      chrome105: "https://developer.chrome.com/blog/new-in-chrome-105/",
      chrome106: "https://developer.chrome.com/blog/new-in-chrome-106/",
      chrome107: "https://developer.chrome.com/blog/new-in-chrome-107/",
      chrome108: "https://developer.chrome.com/blog/new-in-chrome-108/",
      chrome109: "https://developer.chrome.com/blog/new-in-chrome-109/",
      chrome110: "https://developer.chrome.com/blog/new-in-chrome-110/",
      deno1_20: "https://deno.com/blog/v1.20",
      deno1_21: "https://deno.com/blog/v1.21",
      deno1_22: "https://deno.com/blog/v1.22",
      deno1_23: "https://deno.com/blog/v1.23",
      deno1_24: "https://deno.com/blog/v1.24",
      deno1_25: "https://deno.com/blog/v1.25",
      deno1_26: "https://deno.com/blog/v1.26",
      deno1_27: "https://deno.com/blog/v1.27",
      deno1_28: "https://deno.com/blog/v1.28",
      deno1_29: "https://deno.com/blog/v1.29",
      deno1_30: "https://deno.com/blog/v1.30",
      deno1_31: "https://deno.com/blog/v1.31",
      deno1_32: "https://deno.com/blog/v1.32",
      react18: "https://reactjs.org/blog/2022/03/29/react-v18.html",
      react_query4: "https://tanstack.com/blog/announcing-tanstack-query-v4",
      nextjs13: "https://nextjs.org/blog/next-13",
      nextjs13_1: "https://nextjs.org/blog/next-13-1",
      remix1_11: "https://github.com/remix-run/remix/releases/tag/remix@1.11.0",
      remix1_12: "https://github.com/remix-run/remix/releases/tag/remix@1.12.0",
      firefox99: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/99",
      firefox100: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/100",
      firefox101: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/101",
      firefox102: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/102",
      firefox103: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/103",
      firefox104: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/104",
      firefox105: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/105",
      firefox106: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/106",
      firefox107: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/107",
      firefox108: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/108",
      firefox109: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/109",
      firefox110: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/110",
      firefox111: "https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/111",
      swift5_6: "https://www.swift.org/blog/swift-5.6-released/",
      swift5_7: "https://www.swift.org/blog/swift-5.7-released/",
      safari15_4: "https://webkit.org/blog/12445/new-webkit-features-in-safari-15-4/",
      safari15_5: "https://webkit.org/blog/12669/new-webkit-features-in-safari-15-5/",
      safari15_6: "https://webkit.org/blog/13009/new-webkit-features-in-safari-15-6/",
      safari16: "https://webkit.org/blog/13152/webkit-features-in-safari-16-0/",
      safari16_1: "https://webkit.org/blog/13399/webkit-features-in-safari-16-1/",
      safari16_2: "https://webkit.org/blog/13591/webkit-features-in-safari-16-2/",
      go1_18: "https://go.dev/doc/go1.18",
      go1_19: "https://go.dev/doc/go1.19",
      go1_20: "https://go.dev/doc/go1.20",
      rust1_62: "https://blog.rust-lang.org/2022/06/30/Rust-1.62.0.html",
      rust1_63: "https://blog.rust-lang.org/2022/08/11/Rust-1.63.0.html",
      rust1_64: "https://blog.rust-lang.org/2022/09/22/Rust-1.64.0.html",
      rust1_65: "https://blog.rust-lang.org/2022/11/03/Rust-1.65.0.html",
      rust1_66: "https://blog.rust-lang.org/2022/12/15/Rust-1.66.0.html",
      nodejs18: "https://nodejs.org/en/blog/announcements/v18-release-announce/",
      jest28: "https://jestjs.io/blog/2022/04/25/jest-28",
      jest29: "https://jestjs.io/blog/2022/08/25/jest-29",
      ios16: "https://www.apple.com/newsroom/2022/09/ios-16-is-available-today/",
      elixir1_14: "https://elixir-lang.org/blog/2022/09/01/elixir-v1-14-0-released/",
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

    %{dates_to_items: dates_to_items, groups: groups, links: links}
  end
end
