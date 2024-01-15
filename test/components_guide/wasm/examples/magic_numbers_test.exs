defmodule ComponentsGuide.Wasm.Examples.MagicNumbers.Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Wasm
  alias ComponentsGuide.Wasm.Examples.MagicNumbers

  describe "MobileThrottling" do
    alias MagicNumbers.MobileThrottling
    alias MagicNumbers.MobileThrottlingJSON

    test "json encoded size", do: assert(149 = byte_size(MobileThrottlingJSON.json()))
    test "wasm with globals size", do: assert(168 = byte_size(Wasm.to_wasm(MobileThrottling)))

    test "wasm with embedded json size",
      do: assert(224 = byte_size(Wasm.to_wasm(MobileThrottlingJSON)))

    @tag :skip
    test "opt" do
      path_wasm = Path.join(__DIR__, "mobile_throttling.wasm")
      path_wat = Path.join(__DIR__, "mobile_throttling.wat")
      path_opt_wasm = Path.join(__DIR__, "mobile_throttling_OPT.wasm")
      path_opt_wat = Path.join(__DIR__, "mobile_throttling_OPT.wat")
      wasm = Wasm.to_wasm(MobileThrottlingJSON)
      File.write!(path_wasm, wasm)
      System.cmd("wasm-opt", [path_wasm, "-o", path_opt_wasm, "-O"])

      %{size: size} = File.stat!(path_opt_wasm)
      assert size == 168

      {wat, 0} = System.cmd("wasm2wat", [path_wasm])
      File.write!(path_wat, wat)
      {opt_wat, 0} = System.cmd("wasm2wat", [path_opt_wasm])
      File.write!(path_opt_wat, opt_wat)
    end
  end

  # byte_size(Wasm.to_wasm(URLEncoding)) |> dbg()
end
