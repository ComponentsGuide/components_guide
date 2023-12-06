defmodule ComponentsGuide.Wasm.Examples.Lemire.ParseU8Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Examples.Lemire.ParseU8
  alias OrbWasmtime.Instance

  def naive(str) when is_binary(str) do
    i = Instance.run(ParseU8)
    Instance.write_memory(i, 0x100, [0, 0, 0, 0])
    Instance.write_memory(i, 0x100, str |> :binary.bin_to_list())
    Instance.call(i, :parse_uint8_naive, 0x100, byte_size(str))
  end

  def naive(strings) when is_list(strings) do
    multi(strings, :parse_uint8_naive)
  end

  def fastswar(str) when is_binary(str) do
    i = Instance.run(ParseU8)
    Instance.write_memory(i, 0x100, [0, 0, 0, 0])
    Instance.write_memory(i, 0x100, str |> :binary.bin_to_list())
    Instance.call(i, :parse_uint8_fastswar, 0x100, byte_size(str))
  end

  def fastswar(strings) do
    multi(strings, :parse_uint8_fastswar)
  end

  defp multi(strings, func)
       when func in ~w(parse_uint8_naive parse_uint8_fastswar)a do
    i = Instance.run(ParseU8)

    # for str <- strings do
    #   Instance.write_memory(i, 0x100, str |> :binary.bin_to_list())
    #   # Instance.write_string_nul_terminated(i, 0x100, str)
    #   {str, Instance.call(i, func, 0x100, byte_size(str))}
    # end
    Stream.map(strings, fn str ->
      Instance.write_memory(i, 0x100, [0, 0, 0, 0])
      Instance.write_memory(i, 0x100, str |> :binary.bin_to_list())
      {str, Instance.call(i, func, 0x100, byte_size(str))}
    end)
  end

  test "naive" do
    # IO.puts(ParseU8.to_wat())
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

    for result <- naive(for i <- 0..255, do: "#{i}") do
      assert {str, {1, i}} = result
      assert {i, ""} = Integer.parse(str)
    end

    for result <- naive(for i <- 256..9999, do: "#{i}") do
      assert {_, {0, _}} = result
    end
  end

  defp fuzz_chars() do
    0..0xFFFFFF
    |> Stream.map(fn b -> <<b::integer-size(32)>> end)
  end

  test "fastswar" do
    {1, 0} = fastswar("0")
    {1, 1} = fastswar("1")
    {1, 7} = fastswar("7")
    {1, 9} = fastswar("9")
    {1, 99} = fastswar("99")
    {1, 120} = fastswar("120")
    {1, 255} = fastswar("255")
    {0, _} = fastswar("256")
    {0, _} = fastswar("257")
    {0, _} = fastswar("258")
    {0, _} = fastswar("abc")
    {0, _} = fastswar("\0")
    {0, _} = fastswar("\0\0\0\0")

    for result <- fastswar(for i <- 0..255, do: "#{i}") do
      assert {str, {1, i}} = result
      assert {i, ""} = Integer.parse(str)
    end

    for result <- fastswar(for i <- 256..9999, do: "#{i}") do
      assert {_, {0, _}} = result
    end

    fuzz_chars()
    # |> Stream.take_every(13..17 |> Enum.random())
    |> Stream.take_every(2..3 |> Enum.random())
    |> Stream.take_every(2..3 |> Enum.random())
    |> Stream.take_every(2..3 |> Enum.random())
    |> Stream.take_every(2..3 |> Enum.random())
    |> Stream.take_every(2..3 |> Enum.random())
    |> Stream.take_every(2..3 |> Enum.random())
    |> Stream.take_every(2..3 |> Enum.random())
    |> Stream.chunk_every(1024)
    |> Stream.each(fn batch ->
      fastswar(batch) |> Enum.each(fn result ->
        assert {str, result} = result

        case Integer.parse(str) do
          {i, ""} ->
            assert {1, i} = result

          :error ->
            assert {0, _} = result
        end
      end)
    end)
    |> Stream.run()
  end
end
