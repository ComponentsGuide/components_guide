defmodule ComponentsGuide.Wasm.Examples.URLEncoded do
  use Orb
  alias ComponentsGuide.Wasm.Examples.Memory.{BumpAllocator, Copying}
  alias ComponentsGuide.Wasm.Examples.StringBuilder

  use BumpAllocator, export: true
  use Copying
  use StringBuilder

  defmacro __using__(_) do
    quote do
      use BumpAllocator
      use Copying
      use StringBuilder
      use I32.String

      import unquote(__MODULE__)

      Orb.wasm do
        unquote(__MODULE__).funcp(:url_encoded_count)
        unquote(__MODULE__).funcp(:url_encoded_clone_first)
        unquote(__MODULE__).funcp(:url_encoded_decode_first_value)
        unquote(__MODULE__).funcp(:url_encoded_rest)
      end
    end
  end

  wasm U32 do
    func url_encoded_count(url_encoded: I32.U8.Pointer), I32,
      char: I32.U8,
      count: I32,
      pair_char_len: I32 do
      loop EachByte do
        char = url_encoded[at!: 0]

        if I32.in?(char, [?&, 0]) do
          count = count + (pair_char_len > 0)
          pair_char_len = 0
        else
          pair_char_len = pair_char_len + 1
        end

        url_encoded = url_encoded + 1

        EachByte.continue(if: char)
      end

      count
    end

    func url_encoded_clone_first(url_encoded: I32.U8.Pointer), I32.U8.Pointer,
      char: I32.U8,
      len: I32 do
      build_begin!()

      # loop char <- url_encoded, result: I32 do
      loop EachByte, result: I32 do
        char = url_encoded[at!: 0]

        if I32.eq(char, 0) ||| (I32.eq(char, ?&) &&& len > 0) do
          build_done!()
          return()
        end

        if I32.eqz(I32.eq(char, ?&)) do
          append!(u8: char)
          len = len + 1
        end

        url_encoded = url_encoded + 1
        EachByte.continue()
      end
    end

    # Like tl but for url-encoded data
    func url_encoded_rest(url_encoded: I32.U8.Pointer), I32.U8.Pointer, char: I32.U8, len: I32 do
      loop EachByte, result: I32 do
        char = url_encoded[at!: 0]

        if I32.eq(char, 0) ||| (I32.eq(char, ?&) &&& len > 0) do
          url_encoded
          return()
        end

        if I32.eqz(I32.eq(char, ?&)) do
          len = len + 1
        end

        url_encoded = url_encoded + 1
        EachByte.continue()
      end
    end

    func url_encoded_decode_first_value_www_form(url_encoded: I32.U8.Pointer), I32.U8.Pointer do
      0
    end
  end

  def count(), do: call(:url_encoded_count)
  def clone_first(url_encoded), do: call(:url_encoded_clone_first, url_encoded)
  def decode_first_value(url_encoded), do: call(:url_encoded_decode_first_value, url_encoded)
  def rest(url_encoded), do: call(:url_encoded_rest, url_encoded)

  def append_url_query(), do: :todo
end
