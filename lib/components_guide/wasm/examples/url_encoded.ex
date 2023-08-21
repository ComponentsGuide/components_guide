defmodule ComponentsGuide.Wasm.Examples.URLEncoded do
  # https://url.spec.whatwg.org/#application/x-www-form-urlencoded

  use Orb
  alias ComponentsGuide.Wasm.Examples.StringBuilder
  # alias ComponentsGuide.Wasm.Examples.Memory.LinkedLists

  use SilverOrb.BumpAllocator
  use SilverOrb.Mem
  use StringBuilder
  # use LinkedLists

  SilverOrb.BumpAllocator.export_alloc()

  defmacro __using__(_) do
    quote do
      use SilverOrb.BumpAllocator
      use SilverOrb.Mem
      use StringBuilder
      use I32.String

      import unquote(__MODULE__)

      Orb.wasm do
        unquote(__MODULE__).funcp()
      end
    end
  end

  wasm U32 do
    func url_encoded_count(url_encoded: I32.U8.UnsafePointer), I32,
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

    func url_encoded_empty?(url_encoded: I32.U8.UnsafePointer), I32,
      char: I32.U8,
      pair_char_len: I32 do
      loop EachByte, result: I32 do
        char = url_encoded[at!: 0]

        if I32.eq(char, 0) do
          return(1)
        end

        if char |> I32.eq(?&) |> I32.eqz() do
          return(0)
        end

        url_encoded = url_encoded + 1

        EachByte.continue()
      end
    end

    func url_encoded_clone_first(url_encoded: I32.U8.UnsafePointer), I32.U8.UnsafePointer,
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
    func url_encoded_rest(url_encoded: I32.U8.UnsafePointer), I32.U8.UnsafePointer,
      char: I32.U8,
      len: I32 do
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
           url_encoded: I32.U8.UnsafePointer,
           key: I32.U8.UnsafePointer
         ),
         I32.U8.UnsafePointer do
      0
    end

    func url_encoded_first_value_offset(url_encoded: I32.U8.UnsafePointer),
         I32.U8.UnsafePointer,
         char: I32.U8,
         len: I32 do
      loop EachByte, result: I32 do
        char = url_encoded[at!: 0]

        if I32.eq(char, 0) ||| (I32.eq(char, ?&) &&& len > 0) do
          0x0
          return()
        end

        if I32.eq(char, ?=) do
          url_encoded = url_encoded + 1
          char = url_encoded[at!: 0]

          I32.when? I32.in?(char, [0, ?&]) do
            0x0
          else
            url_encoded
          end

          return()
        end

        if I32.eqz(I32.eq(char, ?&)) do
          len = len + 1
        end

        url_encoded = url_encoded + 1
        EachByte.continue()
      end
    end

    func _url_encoded_value_next_char(ptr: I32.U8.UnsafePointer), I32.U8.UnsafePointer,
      next: I32.U8.UnsafePointer,
      next_char: I32.U8 do
      next = I32.when?(I32.eq(Memory.load!(I32.U8, ptr), ?%), do: 3, else: 1) |> I32.add(ptr)
      next_char = Memory.load!(I32.U8, next)
      # next = I32.when?(I32.eq({:i32, :load8_u, ptr}, ?%), do: 3, else: 1) |> I32.add(ptr)
      # next_char = {:i32, :load8_u, next}

      # I32.when? I32.eqz(I32.mul(next_char, I32.xor(?&, next_char))) do
      I32.when? I32.in?(next_char, [0, ?&]) do
        0x0
      else
        next
      end
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
          if (char >= ?a &&& char <= ?z) or
               (char >= ?A &&& char <= ?Z) or
               (char >= ?0 &&& char <= ?9) or
               I32.in?(char, ~C{+:/?#[]@!$&\'()*,;=~_-.}) do
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
            #             append!(
            #               hex_upper:
            #                 push do
            #                   __dup_32 = char >>> 4
            #                 end
            #             )
            #
            #             append!(
            #               hex_upper:
            #                 push do
            #                   __dup_32 = char &&& 15
            #                 end
            #             )
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
            if (char >= ?a &&& char <= ?z) or
                 (char >= ?A &&& char <= ?Z) or
                 (char >= ?0 &&& char <= ?9) or
                 I32.in?(char, ~C{~_-.}) do
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

    func append_url_encode_query_pair_www_form(
           key: I32.U8.UnsafePointer,
           value: I32.U8.UnsafePointer
         ) do
      append!(ascii: ?&)
      typed_call(nil, :append_url_encode_www_form, [key])
      append!(ascii: ?=)
      typed_call(nil, :append_url_encode_www_form, [value])
    end

    func url_encode_www_form(str_ptr: I32.String),
         I32.String,
         char: I32.U8,
         abc: I32,
         __dup_32: I32 do
      build! do
        typed_call(nil, :append_url_encode_www_form, [str_ptr])
      end
    end

    func decode_char_www_form(str: I32.String), I32, c0: I32.U8, c1: I32.U8, c2: I32.U8 do
      c0 = str[at!: 0]

      return(?\0, if: c0 === ?\0)

      I32.match c0 do
        ?% ->
          c1 = str[at!: 1]

          I32.when? c1 === ?\0 do
            ?\0
          else
            c2 = str[at!: 2]

            # TODO: assumes valid input, does not catch/ignore invalid input like %zz
            # See: https://github.com/stedonet/chex
            ((c1 &&& 0x0F) + (c1 >>> 6) * 9) <<< 4
            |> I32.add((c2 &&& 0x0F) + (c2 >>> 6) * 9)
          end

        _ ->
          c0
      end
    end

    #     func url_encode_query_www_form(list_ptr: I32.UnsafePointer), I32.String do
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

  @behaviour Orb.CustomType
  @impl Orb.CustomType
  def wasm_type(), do: :i32

  def initial_i32(), do: 0x0

  def empty?(url_encoded), do: Orb.DSL.typed_call(I32, :url_encoded_empty?, [url_encoded])
  def count(url_encoded), do: Orb.DSL.typed_call(I32, :url_encoded_count, [url_encoded])

  def clone_first(url_encoded),
    do: Orb.DSL.typed_call(I32.U8.UnsafePointer, :url_encoded_clone_first, [url_encoded])

  def rest(url_encoded),
    do: Orb.DSL.typed_call(I32.U8.UnsafePointer, :url_encoded_rest, [url_encoded])

  def decode_first_value_www_form(url_encoded),
    do:
      Orb.DSL.typed_call(I32.U8.UnsafePointer, :url_encoded_decode_first_value_www_form, [
        url_encoded
      ])

  def append_url_query(), do: :todo

  alias __MODULE__

  defmodule Value do
    defmodule Iterator do
      @behaviour Orb.CustomType
      @behaviour Access

      @impl Orb.CustomType
      def wasm_type(), do: :i32

      @impl Access
      def fetch(%Orb.VariableReference{} = var, :valid?) do
        {:ok, URLEncoded.Value.each_char(var)}
      end

      def fetch(%Orb.VariableReference{} = var, :value) do
        {:ok, URLEncoded.Value.each_char(var)}
      end

      def fetch(%Orb.VariableReference{} = var, :next) do
        {:ok, next(var)}
      end

      @impl Access
      def get_and_update(_data, _key, _function) do
        raise UndefinedFunctionError, module: __MODULE__, function: :get_and_update, arity: 3
      end

      @impl Access
      def pop(_data, _key) do
        raise UndefinedFunctionError, module: __MODULE__, function: :pop, arity: 2
      end

      def new(%Orb.MutRef{type: __MODULE__} = mut_ref, source) do
        Orb.MutRef.store(mut_ref, source)
      end

      def new(query) do
        query
        # Orb.call(:url_encoded_first_value_offset, query)
      end

      def next(value_iterator) do
        URLEncoded.rest(value_iterator)
        # Orb.call(:_url_encoded_value_next_char, value_char_iterator)
      end
    end

    defmodule CharIterator do
      @behaviour Orb.CustomType
      @behaviour Access

      @impl Orb.CustomType
      def wasm_type(), do: :i32

      @impl Access
      def fetch(%Orb.VariableReference{} = var, :valid?) do
        # ast = I32.in?(I32.load8_u(var), [?&, 0]) |> I32.eqz()
        {:ok, var}
      end

      def fetch(%Orb.VariableReference{} = var, :value) do
        {:ok, Orb.DSL.typed_call(I32, :decode_char_www_form, [var])}
      end

      def fetch(%Orb.VariableReference{} = var, :next) do
        {:ok, next(var)}
      end

      def new(query) do
        Orb.DSL.typed_call(I32.U8.UnsafePointer, :url_encoded_first_value_offset, [query])
      end

      def next(value_char_iterator) do
        Orb.DSL.call(I32.U8.UnsafePointer, :_url_encoded_value_next_char, [value_char_iterator])
      end
    end

    def each_char(var), do: CharIterator.new(var)
  end

  def each_value(var), do: Value.Iterator.new(var)
end
