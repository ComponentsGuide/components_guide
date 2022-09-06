defmodule ComponentsGuide.Research.Sources.Typescript do
  def fetch(_query) do
    {:text_url, "https://cdn.jsdelivr.net/npm/typescript@4.7.4/lib/lib.dom.d.ts"}
  end

  def search(query, {:ok, source}) do
    start = System.monotonic_time()

    # TODO: add types to a SQLite database?
    {:ok, db} = Exqlite.Sqlite3.open(":memory:")
    :ok = Exqlite.Sqlite3.execute(db, "CREATE VIRTUAL TABLE files USING FTS5(name, body)")

    {:ok, statement} = Exqlite.Sqlite3.prepare(db, "insert into files (name, body) values (?, ?)")
    :ok = Exqlite.Sqlite3.bind(db, statement, ["lib.dom.d.ts", source])
    :done = Exqlite.Sqlite3.step(db, statement)
    :ok = Exqlite.Sqlite3.release(db, statement)

    # Prepare a select statement
    # {:ok, statement} = Exqlite.Sqlite3.prepare(db, "select highlight(files, 1, '<b>', '</b>') body from files where files match ? order by rank")
    {:ok, statement} =
      Exqlite.Sqlite3.prepare(
        db,
        "select snippet(files, 1, '', '', '…', 64) body from files where files match ? order by rank"
      )

    :ok = Exqlite.Sqlite3.bind(db, statement, [query])

    # Get the results
    # {:row, row} = Exqlite.Sqlite3.step(db, statement)
    # :done = Exqlite.Sqlite3.step(db, statement)

    {:ok, rows} = Exqlite.Sqlite3.fetch_all(db, statement)
    {:ok, columns} = Exqlite.Sqlite3.columns(db, statement)
    :ok = Exqlite.Sqlite3.release(db, statement)

    Exqlite.Sqlite3.close(db)

    duration = System.monotonic_time() - start

    IO.puts(
      "SQLite create + text search took #{System.convert_time_unit(duration, :native, :millisecond)}ms"
    )

    {columns, rows}
  end

  defmodule Interface do
    defstruct name: nil, line_start: nil, line_end: nil
  end

  defmodule GlobalVariable do
    defstruct name: nil, line_start: nil, line_end: nil
  end

  defmodule Parser do
    defmodule State do
      defstruct mode: nil, output: []
    end

    def parse(source) when is_binary(source) do
      lines = source |> String.splitter(["\n"]) |> Stream.with_index()

      state = lines |> Enum.reduce(%State{}, &do_reduce/2)
      Enum.reverse(state.output)
    end

    def extract_line_ranges(source, line_ranges) when is_binary(source) do
      lines = source |> String.splitter(["\n"]) |> Stream.with_index()
      lines_map = Map.new(lines, fn {line, n} -> {n, line} end)

      for line_range <- line_ranges do
        line_range =
          case line_range do
            %Range{} = range -> range
            %{line_start: line_start, line_end: line_end} -> Range.new(line_start, line_end)
          end

        for line <- line_range do
          lines_map[line]
        end
        |> Enum.join("\n")
      end
    end

    defmodule ModeDefinition do
      defstruct type: nil, name: nil, line_start: nil, line_end: nil
    end

    def do_reduce({"interface " <> name_and_extends, n}, %State{mode: nil} = state) do
      name = extract_name(name_and_extends)
      mode = %ModeDefinition{type: :interface, name: name, line_start: n}
      %State{state | mode: mode}
    end

    def do_reduce({"declare var " <> name_and_extends, n}, %State{mode: nil} = state) do
      name = extract_name(name_and_extends)
      mode = %ModeDefinition{type: :global_var, name: name, line_start: n}
      %State{state | mode: mode}
    end

    def do_reduce({"}" <> _, n}, %State{mode: %ModeDefinition{}} = state) do
      mode = state.mode

      output_item =
        case mode.type do
          :interface ->
            %Interface{name: mode.name, line_start: mode.line_start, line_end: n}

          :global_var ->
            %GlobalVariable{name: mode.name, line_start: mode.line_start, line_end: n}
        end

      %State{mode: nil, output: [output_item | state.output]}
    end

    def do_reduce(_, state), do: state

    defp extract_name(name_and_extends) do
      case String.split(name_and_extends, [" ", ":"], parts: 2) do
        [name | _] -> name
        _ -> nil
      end
    end
  end
end
