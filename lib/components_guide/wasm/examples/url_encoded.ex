defmodule ComponentsGuide.Wasm.Examples.URLEncoded do
  use Orb
  alias ComponentsGuide.Wasm.Examples.Memory.{BumpAllocator, Copying}

  use BumpAllocator, export: true
  use Copying

  defmacro __using__(_) do
    quote do
      use BumpAllocator
      use Copying
      use I32.String

      import unquote(__MODULE__)

      Orb.wasm do
        unquote(__MODULE__).funcp(:url_encoded_count)
        unquote(__MODULE__).funcp(:url_encoded_decode_first_value)
        unquote(__MODULE__).funcp(:url_encoded_next_pair)
      end
    end
  end

  wasm U32 do
    func url_encoded_count(url_encoded: I32.U8.Pointer), I32,
      char: I32.U8,
      count: I32,
      pair_count: I32 do
      loop EachByte do
        char = url_encoded[at!: 0]

        if I32.in?(char, [?&, 0]) do
          count = count + (pair_count > 0)
          pair_count = 0
        else
          pair_count = pair_count + 1
        end

        # if I32.eq(char, ?&) do
        #   count = count + (pair_count > 0)
        # else
        #   pair_count = pair_count + 1
        # end

        url_encoded = url_encoded + 1

        EachByte.continue(if: char)
      end

      count
    end

    # clone?
    func url_encoded_decode_first_value(url_encoded: I32.U8.Pointer), I32.U8.Pointer do
      0
    end

    # Like tl but for url-encoded data
    func url_encoded_next_pair(url_encoded: I32.U8.Pointer), I32.U8.Pointer do
      url_encoded
    end
  end

  def count(), do: call(:url_encoded_count)
  def decode_first_value(url_encoded), do: call(:decode_first_value, url_encoded)
  def next_pair(url_encoded), do: call(:decode_first_value, url_encoded)

  def append_url_query(), do: :todo
end
