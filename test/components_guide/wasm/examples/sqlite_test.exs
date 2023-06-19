defmodule ComponentsGuide.Wasm.Examples.Sqlite.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Instance

  alias ComponentsGuide.Wasm.Examples.Sqlite.{
    HeightsTable
  }

  describe "HeightsTable" do
    # @tag :skip
    test "works" do
      inst = HeightsTable.start()
      # inst = Instance.run(HeightsTable)

      # init = Instance.capture(inst, :init, 0)
      # add_height = Instance.capture(inst, :add_height, 1)
      # get_count = Instance.capture(inst, :get_count, 0)
      # calc_min = Instance.capture(inst, :calc_min, 0)
      # calc_max = Instance.capture(inst, :calc_max, 0)

      #       init.()
      # 
      #       add_height.(6)
      #       add_height.(5)
      #       add_height.(5)
      #       add_height.(4)
      #       add_height.(6)
      #       add_height.(7)
      # 
      #       assert get_count.() == 6
      # assert calc_min.() == 4
      # assert calc_max.() == 7

      # Instance.cast(inst, :init)
      Instance.call(inst, :init)
      # Instance.cast(inst, :add_height, 6)
    end
  end
end
