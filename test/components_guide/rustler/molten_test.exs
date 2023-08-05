defmodule ComponentsGuide.Rustler.MoltenTest do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Rustler.Molten

  test "add/2" do
    assert Molten.add(3, 4) == 7
  end

  test "js/1" do
    assert Molten.js("5 + 9") == {:ok, "14"}
    assert Molten.js("null") == {:ok, "null"}
    assert Molten.js("'hello'") == {:ok, "hello"}
    assert Molten.js("JSON.stringify(Object.keys({ a: 1, b: 2 }))") == {:ok, ~S(["a","b"])}

    assert Molten.js(~S(import { getHighlighter } from "https://deno.land/x/shiki/shiki/mod.ts";)) ==
             {:error,
              "Uncaught SyntaxError: Cannot use import statement outside a module\n    at <anon>:1:1"}
  end

  test "typescript_module/1" do
    # assert Molten.typescript_module("export const a = 5 + 9") == "14"
    assert Molten.typescript_module("const a = 5 + 9; export default a;") == "14"
  #   assert Molten.typescript_module("null") == "null"
  #   assert Molten.typescript_module("'hello'") == "hello"

  #   assert Molten.typescript_module("JSON.stringify(Object.keys({ a: 1, b: 2 }))") ==
  #            ~S(["a","b"])

  #   assert Molten.typescript_module(
  #            ~S(import { getHighlighter } from "https://deno.land/x/shiki/shiki/mod.ts";)
  #          ) == ~S(["a","b"])
  end

  test "parse_js/1" do
    assert Molten.parse_js("5 + 9") ==
             {:ok,
              %{
                "type" => "Module",
                "body" => [
                  %{
                    "type" => "ExpressionStatement",
                    "expression" => %{
                      "type" => "BinaryExpression",
                      "left" => %{
                        "type" => "NumericLiteral",
                        "raw" => "5",
                        "span" => %{"ctxt" => 0, "end" => 2, "start" => 1},
                        "value" => 5.0
                      },
                      "operator" => "+",
                      "right" => %{
                        "type" => "NumericLiteral",
                        "raw" => "9",
                        "span" => %{"ctxt" => 0, "end" => 6, "start" => 5},
                        "value" => 9.0
                      },
                      "span" => %{"ctxt" => 0, "end" => 6, "start" => 1}
                    },
                    "span" => %{"ctxt" => 0, "end" => 6, "start" => 1}
                  }
                ],
                "interpreter" => nil,
                "span" => %{"ctxt" => 0, "end" => 6, "start" => 1}
              }}
  end
end
