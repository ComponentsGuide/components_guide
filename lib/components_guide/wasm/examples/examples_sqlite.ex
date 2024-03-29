defmodule ComponentsGuide.Wasm.Examples.Sqlite do
  alias OrbWasmtime.Instance

  defmodule Helpers do
    use Orb

    def sqlite3_exec(sql_ptr), do: Orb.DSL.typed_call(I32, :sqlite3_exec, [sql_ptr])
    def sqlite3_prepare(sql_ptr), do: Orb.DSL.typed_call(I32, :sqlite3_prepare, [sql_ptr])
  end

  defmodule HeightsTable do
    use Orb

    Memory.pages(2)

    import Helpers

    # wasm_import(
    #   sqlite3: [
    #     exec: func(name: :sqlite3_exec, params: I32, result: I32),
    #     # exec: func sqlite3_exec(strptr(I32)), I32,
    #     prepare: func(name: :sqlite3_prepare, params: I32, result: I32)
    #   ]
    # )

    defmodule Sqlite3Commands do
      use Orb.Import

      defw(exec(sql: I32.String), I32)
      defw(prepare(sql: I32.String), I32)
    end

    importw(Sqlite3Commands, :sqlite3)

    Orb.__append_body do
      func init() do
        _ =
          Sqlite3Commands.exec(
            ~S"CREATE TABLE heights(id INTEGER PRIMARY KEY AUTOINCREMENT, feet INT)"
          )
      end

      func add_height(height: I32),
        i: I32 do
        _ = Sqlite3Commands.exec(~S"INSERT INTO heights(feet) VALUES (99)")

        # i = json!([i32: height])
        # _ sqlite3_mutate(~S"INSERT INTO heights(feet) values(?)", i)
      end

      func get_count(),
           I32,
           i: I32 do
        # _ sqlite3_prepare(~S"INSERT INTO heights(feet) values(99)")
        Sqlite3Commands.exec(~S"SELECT COUNT(*) FROM heights")
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
           # IO.puts("!!!!!!!!!!")
           # IO.inspect(sql_ptr, label: "sqlite3 exec sql_ptr")
           sql = Instance.Caller.read_string_nul_terminated(caller, sql_ptr)
           # IO.inspect(sql, label: "sqlite3 exec sql")
           :ok = Exqlite.Sqlite3.execute(db, sql)
           0
         end},
        {:sqlite3, :prepare,
         fn _caller, _sql_ptr ->
           0
         end}
      ]

      inst = Instance.run(__MODULE__, imports)
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
