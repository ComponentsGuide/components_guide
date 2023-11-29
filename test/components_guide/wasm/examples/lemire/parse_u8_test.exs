defmodule ComponentsGuide.Wasm.Examples.Lemire.ParseU8Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Examples.Lemire.ParseU8
  alias OrbWasmtime.Instance

  def naive(str) do
    i = Instance.run(ParseU8)
    Instance.write_string_nul_terminated(i, 0x100, str)
    Instance.call(i, :parse_uint8_naive, 0x100, byte_size(str))
  end

  def fastswar(str) do
    i = Instance.run(ParseU8)
    Instance.write_string_nul_terminated(i, 0x100, str)
    Instance.call(i, :parse_uint8_fastswar, 0x100, byte_size(str))
  end

  test "naive" do
    {1, 0} = naive("0")
    {1, 1} = naive("1")
    {1, 7} = naive("7")
    {1, 9} = naive("9")
    {1, 12} = naive("12")
    {1, 88} = naive("88")
    {1, 99} = naive("99")
    {1, 120} = naive("120")
    {1, 255} = naive("255")
    {0, 256} = naive("256")
  end

  test "fastswar" do
    {1, 0} = fastswar("0")
    {1, 1} = fastswar("1")
    {1, 7} = fastswar("7")
    {1, 9} = fastswar("9")
    # {1, 120} = naive("120")
    # {1, 120} = Instance.call(i, :parse_uint8_fastswar, 0x100, 3)
  end
end
