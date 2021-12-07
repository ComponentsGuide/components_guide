defmodule ComponentsGuideWeb.UniversalModulesController do
  use ComponentsGuideWeb, :controller

  alias ComponentsGuideWeb.UniversalModulesParser, as: Parser

  def index(conn, _params) do
    source = "
    const pi = 3.14;

    const answer = 42;
    const negativeAnswer = -42;

    const isEnabled = true;
    const verbose = false;
    "
    # decoded = decode_module(source)
    decoded = Parser.decode(source)

    render(conn, "index.html",
      page_title: "Universal Modules",
      source: source,
      decoded: inspect(decoded)
    )
  end
end

defmodule ComponentsGuideWeb.UniversalModulesParser do
  def switch(submodule, input, result) do
    mod = Module.concat(__MODULE__, submodule)
    apply(mod, :decode, [input, result])
  end

  def decode(input), do: switch(Root, input, [])

  defmodule Root do
    def decode("", result), do: {:ok, Enum.reverse(result)}
    def decode(<<"\n", rest::bitstring>>, result), do: decode(rest, result)
    def decode(<<" ", rest::bitstring>>, result), do: decode(rest, result)
    def decode(<<";", rest::bitstring>>, result), do: decode(rest, result)

    def decode(<<"const ", rest::bitstring>>, result) do
      ComponentsGuideWeb.UniversalModulesParser.switch(Const, rest, result)
    end

    def decode(input, result) do
      {:err, :unexpected_eof, input, result}
    end
  end

  defmodule Const do
    def decode(input, result) do
      decode({:expect_identifier, []}, input, result)
    end

    defp decode(
           {:expect_identifier, _} = context,
           <<" ", rest::bitstring>>,
           result
         ) do
      decode(context, rest, result)
    end

    defp decode(
           {:expect_identifier, reverse_identifier},
           <<"=", rest::bitstring>>,
           result
         ) do
      identifier = reverse_identifier |> Enum.reverse() |> :binary.list_to_bin()
      decode({identifier, :expect_expression, []}, rest, result)
    end

    defp decode(
           {:expect_identifier, reverse_identifier},
           <<char::utf8, rest::bitstring>>,
           result
         ) do
      decode({:expect_identifier, [char | reverse_identifier]}, rest, result)
    end

    # Skip whitespace
    defp decode({_, :expect_expression, []} = context, <<" ", rest::bitstring>>, result),
      do: decode(context, rest, result)

    defp decode(
           {identifier, :expect_expression, expression},
           <<";", rest::bitstring>>,
           result
         ),
         do: Root.decode(rest, [{:const, identifier, expression} | result])

    defp decode(
           {identifier, :expect_expression, []},
           <<"true", rest::bitstring>>,
           result
         ) do
      decode({identifier, :expect_expression, [true]}, rest, result)
    end

    defp decode(
           {identifier, :expect_expression, []},
           <<"false", rest::bitstring>>,
           result
         ) do
      decode({identifier, :expect_expression, [false]}, rest, result)
    end

    defp decode(
           {identifier, :expect_expression, []},
           <<"null", rest::bitstring>>,
           result
         ) do
      decode({identifier, :expect_expression, [nil]}, rest, result)
    end

    defp decode(
           {identifier, :expect_expression, []} = context,
           <<char::utf8, _::bitstring>> = source,
           result
         )
         when char in '0123456789' do
      case Float.parse(source) do
        :error ->
          {:err, context, source, result}

        {f, rest} ->
          decode({identifier, :expect_expression, [f]}, rest, result)
      end
    end

    defp decode(
           {identifier, :expect_expression, []} = context,
           <<"-", char::utf8, _::bitstring>> = source,
           result
         )
         when char in '0123456789' do
      case Float.parse(source) do
        :error ->
          {:err, context, source, result}

        {f, rest} ->
          decode({identifier, :expect_expression, [f]}, rest, result)
      end
    end
  end
end

defmodule ComponentsGuideWeb.UniversalModulesView do
  use ComponentsGuideWeb, :view
end
