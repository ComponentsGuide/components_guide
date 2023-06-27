defmodule ComponentsGuide.Wasm.Examples.URLEncoded.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.URLEncoded

  test "wasm byte size" do
    # IO.puts(URLEncoded.to_wat())
    # assert byte_size(Wasm.to_wasm(URLEncoding)) == 748
  end

  test "url_encoded_count" do
    inst = Instance.run(URLEncoded)
    count = Instance.capture(inst, :url_encoded_count, 1)

    assert count.("") == 0
    assert count.("a") == 1
    assert count.("a&") == 1
    assert count.("a&&") == 1
    assert count.("&a&") == 1
    assert count.("&&a&&") == 1
    assert count.("a=1") == 1
    assert count.("a=1&") == 1
    assert count.("a=1&&") == 1
    assert count.("&&a=1&&") == 1
    assert count.("a=1&b=2") == 2
    assert count.("a=1&&b=2") == 2
    assert count.("a=1&&b=2&") == 2
    assert count.("a=1&&b=2&&") == 2
    assert count.("&&a=1&&b=2&&") == 2
  end

  test "url_encoded_clone_first" do
    inst = Instance.run(URLEncoded)

    clone_first =
      Instance.capture(inst, String, :url_encoded_clone_first, 1)

    assert clone_first.("") == ""
    assert clone_first.("a") == "a"
    assert clone_first.("a&") == "a"
    assert clone_first.("a&&") == "a"
    assert clone_first.("&a&") == "a"
    assert clone_first.("&&a&&") == "a"
    assert clone_first.("a=1") == "a=1"
    assert clone_first.("a=1&") == "a=1"
    assert clone_first.("a=1&&") == "a=1"
    assert clone_first.("&&a=1&&") == "a=1"
    assert clone_first.("a=1&b=2") == "a=1"
    assert clone_first.("a=1&&b=2") == "a=1"
    assert clone_first.("a=1&&b=2&") == "a=1"
    assert clone_first.("a=1&&b=2&&") == "a=1"
    assert clone_first.("&&a=1&&b=2&&") == "a=1"
  end

  test "url_encoded_rest" do
    inst = Instance.run(URLEncoded)

    rest =
      Instance.capture(inst, String, :url_encoded_rest, 1)

    assert rest.("") == ""
    assert rest.("a") == ""
    assert rest.("a&") == "&"
    assert rest.("a&&") == "&&"
    assert rest.("&a&") == "&"
    assert rest.("&&a&&") == "&&"
    assert rest.("a=1") == ""
    assert rest.("a=1&") == "&"
    assert rest.("a=1&&") == "&&"
    assert rest.("&&a=1&&") == "&&"
    assert rest.("a=1&b=2") == "&b=2"
    assert rest.("a=1&&b=2") == "&&b=2"
    assert rest.("a=1&&b=2&") == "&&b=2&"
    assert rest.("a=1&&b=2&&") == "&&b=2&&"
    assert rest.("&&a=1&&b=2&&") == "&&b=2&&"
  end
end
