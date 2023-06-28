defmodule ComponentsGuide.Wasm.Examples.URLEncoded do
  use Orb
  alias ComponentsGuide.Wasm.Examples.Memory.{BumpAllocator, Copying}
  alias ComponentsGuide.Wasm.Examples.StringBuilder
  alias ComponentsGuide.Wasm.Examples.Memory.LinkedLists

  use BumpAllocator
  use Copying
  use StringBuilder
  # use LinkedLists

  BumpAllocator.export_alloc()

  defmacro __using__(_) do
    quote do
      use BumpAllocator
      use Copying
      use StringBuilder
      use I32.String

      import unquote(__MODULE__)

      Orb.wasm do
        unquote(__MODULE__).funcp()
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

    func url_encoded_decode_first_value_www_form(
           url_encoded: I32.U8.Pointer,
           key: I32.U8.Pointer
         ),
         I32.U8.Pointer do
      0
    end
  end

  wasm U32 do
    func url_encode_rfc3986(str_ptr: I32.String),
         I32.String,
         char: I32.U8,
         abc: I32,
         __dup_32: I32 do
      build_begin!()

      loop EachByte do
        char = str_ptr[at!: 0]

        if char do
          if I32.in_inclusive_range?(char, ?a, ?z)
             |> I32.or(I32.in_inclusive_range?(char, ?A, ?Z))
             |> I32.or(I32.in_inclusive_range?(char, ?0, ?9))
             |> I32.or(I32.in?(char, ~C{+:/?#[]@!$&\'()*,;=~_-.})) do
            append!(ascii: char)
          else
            append!(ascii: ?%)
            append!(hex_upper: char >>> 4)
            append!(hex_upper: char &&& 15)
            # append!(hex_upper: I32.div_u(char, 16))
            # append!(hex_upper: I32.rem_u(char, 16))

            # __dup_32 = I32.div_u(char, 16)
            # append!(hex_upper: __dup_32)
            # __dup_32 = I32.rem_u(char, 16)
            # append!(hex_upper: __dup_32)

            # append!(hex_upper: local_tee(:__dup_32, I32.div_u(char, 16)))
            # append!(hex_upper: local_tee(:__dup_32, I32.rem_u(char, 16)))
          end

          str_ptr = str_ptr + 1
          EachByte.continue()
        end
      end

      build_done!()
    end

    func append_url_encode_www_form(str_ptr: I32.String),
      char: I32.U8,
      abc: I32,
      __dup_32: I32 do
      loop EachByte do
        char = str_ptr[at!: 0]

        if char do
          if I32.eq(char, 0x20) do
            append!(ascii: ?+)
          else
            if I32.in_inclusive_range?(char, ?a, ?z)
               |> I32.or(I32.in_inclusive_range?(char, ?A, ?Z))
               |> I32.or(I32.in_inclusive_range?(char, ?0, ?9))
               |> I32.or(I32.in?(char, ~C{~_-.})) do
              append!(ascii: char)
            else
              append!(ascii: ?%)
              append!(hex_upper: char >>> 4)
              append!(hex_upper: char &&& 15)
              # append!(hex_upper: I32.div_u(char, 16))
              # append!(hex_upper: I32.rem_u(char, 16))

              # __dup_32 = I32.div_u(char, 16)
              # append!(hex_upper: __dup_32)
              # __dup_32 = I32.rem_u(char, 16)
              # append!(hex_upper: __dup_32)

              # append!(hex_upper: local_tee(:__dup_32, I32.div_u(char, 16)))
              # append!(hex_upper: local_tee(:__dup_32, I32.rem_u(char, 16)))
            end
          end

          str_ptr = str_ptr + 1
          EachByte.continue()
        end
      end
    end

    func append_url_encode_query_pair_www_form(key: I32.U8.Pointer, value: I32.U8.Pointer) do
      append!(ascii: ?&)
      call(:append_url_encode_www_form, key)
      append!(ascii: ?=)
      call(:append_url_encode_www_form, value)
    end

    func url_encode_www_form(str_ptr: I32.String),
         I32.String,
         char: I32.U8,
         abc: I32,
         __dup_32: I32 do
      build! do
        call(:append_url_encode_www_form, str_ptr)
      end
    end

    #     func url_encode_query_www_form(list_ptr: I32.Pointer), I32.String do
    #       build! do
    #         loop EachPair do
    #           append!(string: LinkedLists.hd!(LinkedLists.hd!(list_ptr)))
    #           append!(ascii: ?=)
    #           append!(string: LinkedLists.hd!(LinkedLists.tl!(LinkedLists.hd!(list_ptr))))
    # 
    #           list_ptr = LinkedLists.tl!(list_ptr)
    # 
    #           if list_ptr do
    #             append!(ascii: ?&)
    #           end
    # 
    #           EachPair.continue(if: list_ptr)
    #         end
    #       end
    #     end
  end

  def count(url_encoded), do: call(:url_encoded_count, url_encoded)
  def clone_first(url_encoded), do: call(:url_encoded_clone_first, url_encoded)
  def rest(url_encoded), do: call(:url_encoded_rest, url_encoded)

  def decode_first_value_www_form(url_encoded),
    do: call(:url_encoded_decode_first_value_www_form, url_encoded)

  def append_url_query(), do: :todo

  defmodule ValueCharIterator do
    @behaviour Orb.Type

    @impl Orb.Type
    def wasm_type(), do: :i32

    def new(query_iterator) do
      query_iterator
    end

    def next(value_char_iterator) do
      I32.add(value_char_iterator, 1)
    end
  end
end
