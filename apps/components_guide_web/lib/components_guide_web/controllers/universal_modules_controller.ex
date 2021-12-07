defmodule ComponentsGuideWeb.UniversalModulesController do
  use ComponentsGuideWeb, :controller

  def index(conn, _params) do
    source = "
    const pi = 3.14;

    const answer = 42;
    "
    decoded = decode_module(source)
    render(conn, "index.html", source: source, decoded: inspect(decoded))
  end

  defp decode_module(source) do
    decode_module(nil, source, [])
  end

  defp decode_module(nil, <<"\n", rest::bitstring>>, result),
    do: decode_module(nil, rest, result)

  # Skip semicolons
  defp decode_module(nil, <<";", rest::bitstring>>, result),
    do: decode_module(nil, rest, result)

  # Skip semicolons
  defp decode_module(nil, <<" ", rest::bitstring>>, result),
    do: decode_module(nil, rest, result)

  defp decode_module(nil, <<"const ", rest::bitstring>>, result) do
    decode_module({:const, :expect_identifier, []}, rest, result)
  end

  # Skip whitespace
  defp decode_module({_, :expect_identifier, []} = context, <<" ", rest::bitstring>>, result),
    do: decode_module(context, rest, result)

  # Skip whitespace
  defp decode_module({_, :expect_expression, []} = context, <<" ", rest::bitstring>>, result),
    do: decode_module(context, rest, result)

  defp decode_module(
         {:const, :expect_identifier, _} = context,
         <<" ", rest::bitstring>>,
         result
       ) do
    decode_module(context, rest, result)
  end

  defp decode_module(
         {:const, :expect_identifier, reverse_identifier},
         <<"=", rest::bitstring>>,
         result
       ) do
    identifier = reverse_identifier |> Enum.reverse() |> :binary.list_to_bin()
    decode_module({{:const, identifier}, :expect_expression, []}, rest, result)
  end

  defp decode_module(
         {:const, :expect_identifier, reverse_identifier},
         <<char::utf8, rest::bitstring>>,
         result
       ) do
    decode_module({:const, :expect_identifier, [char | reverse_identifier]}, rest, result)
  end

  defp decode_module(
         {{:const, identifier}, :expect_expression, expression},
         <<";", rest::bitstring>>,
         result
       ),
       do: decode_module(nil, rest, [{:const, identifier, expression} | result])

  defp decode_module(
         {{:const, identifier}, :expect_expression, []} = context,
         <<char::utf8, _::bitstring>> = source,
         result
       )
       when char in [?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9] do
    case Float.parse(source) do
      :error ->
        err(context, source, result)

      {f, rest} ->
        decode_module({{:const, identifier}, :expect_expression, [f]}, rest, result)
    end
  end

  defp decode_module(nil, "", result) do
    {:ok, Enum.reverse(result)}
  end

  defp decode_module(context, source, result) do
    err(context, source, result)
  end

  defp err(context, source, result) do
    {:err, context, source, result}
  end
end

defmodule ComponentsGuideWeb.UniversalModulesView do
  use ComponentsGuideWeb, :view
end
