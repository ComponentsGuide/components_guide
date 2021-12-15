defmodule ComponentsGuideWeb.UniversalModulesController do
  use ComponentsGuideWeb, :controller

  alias ComponentsGuideWeb.UniversalModulesParser, as: Parser

  def index(conn, _params) do
    source = """
    const pi = 3.14;

    export const answer = 42;
    const negativeAnswer = -42;

    const isEnabled = true;
    const verbose = false;
    const alwaysNull = null;

    const debug = verbose;

    export const dateFormat = "YYYY/MM/DD";

    const exampleDotOrg = new URL("https://example.org");

    const array = [1, 2, 3];
    const arrayMultiline = [
      4,
      5,
      6
    ];
    export const flavors = ["vanilla", "chocolate", "caramel", "raspberry"];
    export const flavorsSet = new Set(["vanilla", "chocolate", "caramel", "raspberry"]);

    const object = { "key": "value" };

    function hello() {}
    function* gen() {
      const a = 1;
      yield [1, 2, 3];
    }
    """
    # decoded = decode_module(source)
    decoded = Parser.decode(source)
    identifiers = ComponentsGuideWeb.UniversalModulesInspector.list_identifiers(elem(decoded, 1))

    render(conn, "index.html",
      page_title: "Universal Modules",
      source: source,
      decoded: inspect(decoded),
      identifiers: inspect(identifiers),
    )
  end
end

defmodule ComponentsGuideWeb.UniversalModulesInspector do
  def is_identifier({:const, _, _}), do: true
  def is_identifier({:function, _, _, _}), do: true
  def is_identifier({:generator_function, _, _, _}), do: true
  def is_identifier(_), do: false

  def list_identifiers(module_body) do
    for statement <- module_body, is_identifier(statement), do: statement
  end
end

defmodule ComponentsGuideWeb.UniversalModulesParser do
  def compose(submodule, input) do
    mod = Module.concat(__MODULE__, submodule)
    apply(mod, :decode, [input])
  end

  # def decode(input), do: Root.decode(input, [])
  def decode(input), do: switch(Root, input, [])

  defp switch(submodule, input, result) do
    mod = Module.concat(__MODULE__, submodule)
    apply(mod, :decode, [input, result])
  end

  defmodule Root do
    defdelegate compose(submodule, input), to: ComponentsGuideWeb.UniversalModulesParser

    def decode("", result), do: {:ok, Enum.reverse(result)}
    def decode(<<"\n", rest::bitstring>>, result), do: decode(rest, result)
    def decode(<<" ", rest::bitstring>>, result), do: decode(rest, result)
    def decode(<<";", rest::bitstring>>, result), do: decode(rest, result)

    def decode(<<"const ", _::bitstring>> = input, result) do
      case compose(Const, input) do
        {:ok, term, rest} ->
          decode(rest, [term | result])

        {:error, reason} ->
          {:error, reason}
      end
    end

    def decode(<<"export ", _::bitstring>> = input, result) do
      case compose(Export, input) do
        {:ok, term, rest} ->
          decode(rest, [term | result])

        {:error, reason} ->
          {:error, reason}
      end
    end

    def decode(<<"function", _::bitstring>> = input, result) do
      case compose(Function, input) do
        {:ok, term, rest} ->
          decode(rest, [term | result])

        {:error, reason} ->
          {:error, reason}
      end
    end

    def decode(input, result) do
      {:error, :unexpected_eof, input, result}
    end
  end

  defmodule Export do
    def decode(<<"export ", rest::bitstring>>) do
      case ComponentsGuideWeb.UniversalModulesParser.compose(Const, rest) do
        {:ok, term, rest} ->
          {:ok, {:export, term}, rest}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defmodule Function do
    defdelegate compose(submodule, input), to: ComponentsGuideWeb.UniversalModulesParser

    def decode(<<"function", rest::bitstring>>),
      do: decode(%{generator_mark: nil, name: nil, args: nil, body: nil}, rest)

    defp decode(context, <<" ", rest::bitstring>>),
      do: decode(context, rest)

    defp decode(%{generator_mark: nil, name: nil, args: nil} = context, <<"*", rest::bitstring>>),
      do: decode(%{context | generator_mark: true}, rest)

    defp decode(%{name: nil, args: nil} = context, <<"(", rest::bitstring>>),
      do: decode(%{context | args: {:open, []}}, rest)

    defp decode(%{name: reverse_name, args: nil} = context, <<"(", rest::bitstring>>) do
      name = reverse_name |> Enum.reverse() |> :binary.list_to_bin()
      decode(%{context | name: name, args: {:open, []}}, rest)
    end

    defp decode(%{args: {:open, args}} = context, <<")", rest::bitstring>>),
      do: decode(%{context | args: {:closed, args}}, rest)

    defp decode(%{args: {:closed, _}, body: nil} = context, <<"{", rest::bitstring>>),
      do: decode(%{context | body: {:open, []}}, rest)

    defp decode(%{args: {:closed, args}, name: name, body: {:open, body_items}} = context, <<"}", rest::bitstring>>) do
      case context.generator_mark do
        true ->
          {:ok, {:generator_function, name, args, Enum.reverse(body_items)}, rest}

        nil ->
          {:ok, {:function, name, args, Enum.reverse(body_items)}, rest}
      end
    end

    defp decode(%{body: {:open, _}} = context, <<char::utf8, rest::bitstring>>) when char in [?\n, ?\t, ?;],
      do: decode(context, rest)

    defp decode(%{body: {:open, body_items}} = context, <<"const ", _::bitstring>> = input) do
      case compose(Const, input) do
        {:ok, term, rest} ->
          decode(%{context | body: {:open, [term | body_items]}}, rest)

        {:error, reason} ->
          {:error, {reason, body_items}}
      end
    end

    defp decode(%{body: {:open, body_items}} = context, <<"yield ", _::bitstring>> = input) do
      case compose(Yield, input) do
        {:ok, term, rest} ->
          decode(%{context | body: {:open, [term | body_items]}}, rest)

        {:error, reason} ->
          {:error, {reason, body_items}}
      end
    end

    defp decode(%{name: nil, args: nil} = context, <<char::utf8, rest::bitstring>>),
      do: decode(%{context | name: [char]}, rest)

    defp decode(%{name: name, args: nil} = context, <<char::utf8, rest::bitstring>>) do
      name = [char | name]
      decode(%{context | name: name}, rest)
    end
  end

  defmodule Yield do
    def decode(<<"yield ", rest::bitstring>>) do
      case ComponentsGuideWeb.UniversalModulesParser.compose(Expression, rest) do
        {:ok, term, rest} ->
          {:ok, {:yield, term}, rest}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defmodule Const do
    def decode(<<"const ", rest::bitstring>>),
      do: decode({:expect_identifier, []}, rest)

    def decode(<<_::bitstring>>),
      do: {:error, :expected_const}

    defp decode({:expect_identifier, _} = context, <<" ", rest::bitstring>>),
      do: decode(context, rest)

    defp decode({:expect_identifier, reverse_identifier}, <<"=", rest::bitstring>>) do
      identifier = reverse_identifier |> Enum.reverse() |> :binary.list_to_bin()
      decode({identifier, :expect_expression, []}, rest)
    end

    defp decode({:expect_identifier, reverse_identifier}, <<char::utf8, rest::bitstring>>) do
      decode({:expect_identifier, [char | reverse_identifier]}, rest)
    end

    # Skip whitespace
    defp decode({_, :expect_expression, []} = context, <<" ", rest::bitstring>>),
      do: decode(context, rest)

    defp decode({identifier, :expect_expression, expression}, ""),
      do: {:ok, {:const, identifier, expression}, ""}

    defp decode({identifier, :expect_expression, []}, input) do
      case ComponentsGuideWeb.UniversalModulesParser.compose(Expression, input) do
        {:ok, expression, rest} ->
          {:ok, {:const, identifier, expression}, rest}

        {:error, error} ->
          {:error, {:invalid_expression, error}}
      end
    end
  end

  defmodule Expression do
    import Unicode.Guards

    def decode(input), do: decode([], input)

    defp finalize([{:found_identifier, reverse_identifier} | context_rest]) do
      identifier = reverse_identifier |> Enum.reverse() |> :binary.list_to_bin()
      [{:ref, identifier} | context_rest]
    end

    defp finalize(expression), do: expression

    defp decode(expression, <<";", rest::bitstring>>),
      do: {:ok, finalize(expression), rest}

    defp decode([] = context, <<" ", rest::bitstring>>), do: decode(context, rest)
    defp decode([], <<"true", rest::bitstring>>), do: decode(true, rest)
    defp decode([], <<"false", rest::bitstring>>), do: decode(false, rest)
    defp decode([], <<"null", rest::bitstring>>), do: decode(nil, rest)

    defp decode([], <<"new URL(", rest::bitstring>>) do
      [encoded_json, rest] = String.split(rest, ");\n", parts: 2)
      case Jason.decode(encoded_json) do
        {:ok, value} ->
          {:ok, {:url, value}, rest}

        {:error, error} ->
          {:error, error}
      end
    end

    defp decode([], <<"new Set(", rest::bitstring>>) do
      [encoded_json, rest] = String.split(rest, ");\n", parts: 2)
      case Jason.decode(encoded_json) do
        {:ok, value} ->
          {:ok, {:set, value}, rest}

        {:error, error} ->
          {:error, error}
      end
    end

    # TODO: parse JSON by finding the end character followed by a semicolon + newline.
    # JSON strings cannoc contain literal newlines (it’s considered to be a control character),
    # so instead it must be encoded as "\n". So we can use this fast to know an actual newline is
    # outside the JSON value.
    # defp decode([], <<"{", rest::bitstring>>), do: decode([nil], rest)
    defp decode([], <<char::utf8, _::bitstring>> = input) when char in [?[, ?{, ?"] do
      [encoded_json, rest] = String.split(input, ";\n", parts: 2)
      case Jason.decode(encoded_json) do
        {:ok, value} ->
          {:ok, value, rest}

        {:error, error} ->
          {:error, error}
      end
    end

    defp decode([] = context, <<char::utf8, _::bitstring>> = source) when char in '0123456789' do
      case Float.parse(source) do
        :error ->
          {:error, {:invalid_number, context, source}}

        {f, rest} ->
          decode(f, rest)
      end
    end

    defp decode([] = context, <<"-", char::utf8, _::bitstring>> = source)
         when char in '0123456789' do
      case Float.parse(source) do
        :error ->
          {:error, {:invalid_number, context, source}}

        {f, rest} ->
          decode(f, rest)
      end
    end

    defp decode([], <<char::utf8, rest::bitstring>>) when is_lower(char) or is_upper(char),
      do: decode([{:found_identifier, [char]}], rest)

    defp decode([{:found_identifier, reverse_identifier} | context_rest], <<char::utf8, rest::bitstring>>)
         when is_lower(char) or is_upper(char) or is_digit(char) do
      decode([{:found_identifier, [char | reverse_identifier]} | context_rest], rest)
    end
  end

  defmodule KnownIdentifier do
    defmodule Symbol do
    end

    defmodule URL do
    end

    defmodule URLSearchParams do
    end

    def decode(<<"Symbol", rest::bitstring>>), do: {:ok, __MODULE__.Symbol, rest}
    def decode(<<"URL", rest::bitstring>>), do: {:ok, __MODULE__.URL, rest}
    def decode(<<"URLSearchParams", rest::bitstring>>), do: {:ok, __MODULE__.URLSearchParams, rest}

    def decode(_), do: {:error, :unknown_identifier}
  end
end

defmodule ComponentsGuideWeb.UniversalModulesView do
  use ComponentsGuideWeb, :view
end
