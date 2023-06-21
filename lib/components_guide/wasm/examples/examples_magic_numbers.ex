defmodule ComponentsGuide.Wasm.Examples.MagicNumbers do
  alias ComponentsGuide.Wasm
  alias ComponentsGuide.WasmBuilder
  alias ComponentsGuide.Wasm.Examples.Memory.BumpAllocator

  defmodule MobileThrottling do
    use WasmBuilder

    I32.global(:export_readonly,
      slow_3g_latency_ms: 2000,
      slow_3g_download: 50_000,
      slow_3g_upload: 50_000
    )

    I32.global(:export_readonly,
      fast_3g_latency_ms: 563,
      fast_3g_download: 180_000,
      fast_3g_upload: 84_375
    )

    wasm do
    end
  end
end
