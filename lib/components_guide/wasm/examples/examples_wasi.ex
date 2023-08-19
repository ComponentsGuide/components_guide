defmodule ComponentsGuide.Wasm.Examples.WASI do
  alias OrbWasmtime.Instance

  # See https://github.com/bjorn3/browser_wasi_shim/blob/3fbfb16a79d9ae6de6b034c3641746bbdc2a4184/src/wasi.ts#L96
  # See https://github.com/WebAssembly/WASI/blob/33de9e568c35424765e7b10952b181f01a724fca/legacy/preview1/docs.md#-clock_time_getid-clockid-precision-timestamp---resulttimestamp-errno
  defmodule Clock do
    use Orb

    # export const CLOCKID_REALTIME = 0;
    # export const CLOCKID_MONOTONIC = 1;
    # export const CLOCKID_PROCESS_CPUTIME_ID = 2;
    # export const CLOCKID_THREAD_CPUTIME_ID = 3;
    @clockid [
               :realtime,
               :monotonic,
               :process_cputime_id,
               :thread_cputime_id
             ]
             |> Enum.with_index()
             |> Map.new(fn {key, index} -> {key, {:i32_const, index}} end)

    wasm_import(:wasi_unstable,
      clock_res_get: Orb.DSL.funcp(name: :clock_res_get, params: [I32, I32], result: I32),
      clock_time_get: Orb.DSL.funcp(name: :clock_time_get, params: [I32, I64, I32], result: I32)
    )

    wasm do
    end

    import Kernel

    # Write 64-bit number in little-endian format
    def clock_res_get(instance, _clockid, address) do
      Instance.write_i64(instance, address, 0)
    end

    def clock_time_get(instance, clockid, _precision, address) do
      {:i32_const, realtime} = @clockid.realtime
      {:i32_const, monotonic} = @clockid.monotonic

      case clockid do
        ^realtime ->
          Instance.write_i64(instance, address, 0)

        ^monotonic ->
          Instance.write_i64(instance, address, 0)

        _ ->
          Instance.write_i64(instance, address, 0)
      end

      0
    end
  end
end
