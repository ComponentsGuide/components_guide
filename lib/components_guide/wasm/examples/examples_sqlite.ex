defmodule ComponentsGuide.Wasm.Examples.Sqlite do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.WasmBuilder

  defmodule Helpers do
    use WasmBuilder

    def sqlite3_exec(sql_ptr), do: call(:sqlite3_exec, sql_ptr)
    def sqlite3_prepare(sql_ptr), do: call(:sqlite3_prepare, sql_ptr)
  end

  defmodule HeightsTable do
    use WasmBuilder

    defmacro __using__(_opts) do
      quote do
        # @wasm_memory 1

        import WasmBuilder

        wasm do
          unquote(__MODULE__).funcp(:memcpy)
        end

        import unquote(__MODULE__)
      end
    end

    @wasm_memory 2

    import Helpers

    defwasm imports: [
              sqlite3: [
                exec: func(name: :sqlite3_exec, params: I32, result: I32),
                prepare: func(name: :sqlite3_prepare, params: I32, result: I32)
              ]
            ] do
      func init(), nil do
        _ = sqlite3_exec(~S"CREATE TABLE heights(id INTEGER PRIMARY KEY AUTOINCREMENT, feet INT)")
      end

      func add_height(height(I32)),
           nil,
           i: I32 do
        # _ sqlite3_prepare(~S"INSERT INTO heights(feet) values(99)")
        _ = sqlite3_exec(~S"INSERT INTO heights(feet) VALUES (99)")
      end

      func get_count(),
           I32,
           i: I32 do
        # _ sqlite3_prepare(~S"INSERT INTO heights(feet) values(99)")
        sqlite3_exec(~S"SELECT COUNT(*) FROM heights")
      end
    end

    def start() do
      {:ok, db} = Exqlite.Sqlite3.open(":memory:")

      imports = [
        {:log, :int32,
         fn value ->
           IO.inspect(value, label: "wasm log int32")
           0
         end},
        {:sqlite3, :exec,
         fn caller, sql_ptr ->
           IO.puts("!!!!!!!!!!")
           IO.inspect(sql_ptr, label: "sqlite3 exec sql_ptr")
           sql = Wasm.Instance.Caller.read_string_nul_terminated(caller, sql_ptr)
           IO.inspect(sql, label: "sqlite3 exec sql")
           :ok = Exqlite.Sqlite3.execute(db, sql)
           0
         end},
        {:sqlite3, :prepare,
         fn caller, sql_ptr ->
           0
         end}
      ]

      inst = Wasm.Instance.run(__MODULE__, imports)
      {inst, db}
    end

    def demo() do
      {:ok, db} = Exqlite.Sqlite3.open(":memory:")
      :ok = Exqlite.Sqlite3.execute(db, "CREATE VIRTUAL TABLE files USING FTS5(name, body)")

      {:ok, statement} =
        Exqlite.Sqlite3.prepare(db, "insert into files (name, body) values (?, ?)")

      :ok = Exqlite.Sqlite3.bind(db, statement, ["lib.dom.d.ts", "// hello"])
      :done = Exqlite.Sqlite3.step(db, statement)
      :ok = Exqlite.Sqlite3.release(db, statement)
    end
  end
end
