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
    defstruct name: nil, doc: nil, line_start: nil, line_end: nil
  end

  defmodule Namespace do
    defstruct name: nil, doc: nil, line_start: nil, line_end: nil
  end

  defmodule GlobalVariable do
    defstruct name: nil, doc: nil, line_start: nil, line_end: nil
  end

  defmodule GlobalFunction do
    defstruct name: nil, doc: nil, line_start: nil, line_end: nil
  end

  defmodule Parser do
    defmodule State do
      defstruct mode: nil, prev_doc: nil, output: []
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
      defstruct type: nil, name: nil, doc: nil, line_start: nil, line_end: nil
    end

    defmodule JSDoc do
      defstruct message: nil, line_start: nil
    end

    def do_reduce({"/**" <> rest_of_comment, n}, %State{mode: nil} = state) do
      {mode, prev_doc} =
        case rest_of_comment |> String.replace_suffix("*/", "") do
          # <<a:bytes-size(byte_size(rest_of_comment))>> -> {%ModeDefinition{type: :doc_comment, line_start: n}, nil}
          s when byte_size(rest_of_comment) == byte_size(s) ->
            {%JSDoc{message: String.trim(rest_of_comment), line_start: n}, nil}

          message ->
            {nil, %JSDoc{message: String.trim(message), line_start: n}}
        end

      %State{state | mode: mode, prev_doc: prev_doc}
    end

    def do_reduce({"interface " <> name_and_extends, n}, %State{mode: nil} = state) do
      name = extract_name(name_and_extends)

      {doc, line_start} = read_prev_doc(state, n)

      mode = %ModeDefinition{type: :interface, name: name, doc: doc, line_start: line_start}
      %State{state | mode: mode, prev_doc: nil}
    end

    def do_reduce({"declare namespace " <> name_and_extends, n}, %State{mode: nil} = state) do
      name = extract_name(name_and_extends)

      {doc, line_start} = read_prev_doc(state, n)

      mode = %ModeDefinition{type: :namespace, name: name, doc: doc, line_start: line_start}
      %State{state | mode: mode, prev_doc: nil}
    end

    def do_reduce({"declare var " <> name_and_extends, n}, %State{mode: nil} = state) do
      name = extract_name(name_and_extends)

      case name_and_extends |> String.trim_trailing() |> String.ends_with?(";") do
        true ->
          {doc, line_start} = read_prev_doc(state, n)

          output_item = %GlobalVariable{
            name: name,
            doc: doc,
            line_start: line_start,
            line_end: n
          }

          %State{mode: nil, output: [output_item | state.output], prev_doc: nil}

        false ->
          mode = %ModeDefinition{type: :global_var, name: name, line_start: n}
          %State{state | mode: mode, prev_doc: nil}
      end
    end

    def do_reduce({"declare function " <> name_and_more, n}, %State{mode: nil} = state) do
      name = extract_name(name_and_more)

      {doc, line_start} = read_prev_doc(state, n)

      output_item = %GlobalFunction{
        name: name,
        doc: doc,
        line_start: line_start,
        line_end: n
      }

      %State{mode: nil, output: [output_item | state.output], prev_doc: nil}
    end

    def do_reduce({line, _n}, %State{mode: %JSDoc{message: message}} = state) do
      case line |> String.ends_with?("*/") do
        false ->
          line =
            case line |> String.trim() do
              "*" <> rest -> rest |> String.trim_leading()
              s -> s
            end

          message =
            case message do
              "" -> line
              message -> message <> "\n" <> line
            end

          mode = %JSDoc{state.mode | message: message}
          %State{state | mode: mode}

        true ->
          prev_doc = %JSDoc{message: message, line_start: state.mode.line_start}
          %State{state | mode: nil, prev_doc: prev_doc}
      end
    end

    def do_reduce({"}" <> _, n}, %State{mode: %ModeDefinition{}} = state) do
      mode = state.mode

      output_item =
        case mode.type do
          :interface ->
            %Interface{
              name: mode.name,
              doc: mode.doc,
              line_start: mode.line_start,
              line_end: n
            }

          :namespace ->
            %Namespace{
              name: mode.name,
              doc: mode.doc,
              line_start: mode.line_start,
              line_end: n
            }

          :global_var ->
            %GlobalVariable{
              name: mode.name,
              doc: mode.doc,
              line_start: mode.line_start,
              line_end: n
            }
        end

      %State{mode: nil, output: [output_item | state.output]}
    end

    def do_reduce(_, state), do: state

    defp extract_name(name_and_extends) do
      case String.split(name_and_extends, [" ", ":", "("], parts: 2) do
        [name | _] -> name
        _ -> nil
      end
    end

    defp read_prev_doc(%State{prev_doc: %JSDoc{message: doc, line_start: doc_n}}, _n) do
      {doc, doc_n}
    end

    defp read_prev_doc(_, n), do: {nil, n}
  end
end
