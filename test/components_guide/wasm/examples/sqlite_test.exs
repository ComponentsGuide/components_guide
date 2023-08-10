defmodule ComponentsGuide.Wasm.Examples.Sqlite.Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  alias ComponentsGuide.Wasm.Examples.Sqlite.{
    HeightsTable
  }

  describe "HeightsTable" do
    test "works" do
      {inst, db} = HeightsTable.start()
      # inst = Instance.run(HeightsTable)

      init = Instance.capture(inst, :init, 0)
      add_height = Instance.capture(inst, :add_height, 1)
      # get_count = Instance.capture(inst, :get_count, 0)
      # calc_min = Instance.capture(inst, :calc_min, 0)
      # calc_max = Instance.capture(inst, :calc_max, 0)

      init.()
      add_height.(6)
      add_height.(5)
      add_height.(5)
      add_height.(4)
      add_height.(6)
      add_height.(7)
      #
      #       assert get_count.() == 6
      # assert calc_min.() == 4
      # assert calc_max.() == 7

      # Instance.cast(inst, :init)
      # Instance.call(inst, :init)
      # Instance.call(inst, :add_height, 6)

      {:ok, statement} = Exqlite.Sqlite3.prepare(db, "select * from heights")
      rows = Exqlite.Sqlite3.fetch_all(db, statement)
      assert rows == {:ok, [[1, 99], [2, 99], [3, 99], [4, 99], [5, 99], [6, 99]]}

      # IO.inspect(rows)
    end
  end
end
