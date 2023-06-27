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
    url_encoded_count = Instance.capture(inst, :url_encoded_count, 1)

    assert url_encoded_count.("") == 0
    assert url_encoded_count.("a") == 1
    assert url_encoded_count.("a&") == 1
    assert url_encoded_count.("a&&") == 1
    assert url_encoded_count.("&a&&") == 1
    assert url_encoded_count.("&&a&&") == 1
    assert url_encoded_count.("a=1") == 1
    assert url_encoded_count.("a=1&") == 1
    assert url_encoded_count.("a=1&&") == 1
    assert url_encoded_count.("a=1&b=2") == 2
    assert url_encoded_count.("a=1&&b=2") == 2
    assert url_encoded_count.("a=1&&b=2&") == 2
    assert url_encoded_count.("a=1&&b=2&&") == 2
  end

  test "url_encoded_clone_first_value" do
    inst = Instance.run(URLEncoded)

    clone_first_pair =
      Instance.capture(inst, String, :url_encoded_clone_first_pair, 1)

    assert clone_first_pair.("") == ""
    assert clone_first_pair.("a") == "a"
    assert clone_first_pair.("a&") == "a"
    assert clone_first_pair.("a&&") == "a"
    # assert clone_first_pair.("&a&&") == 1
    # assert clone_first_pair.("&&a&&") == 1
    # assert clone_first_pair.("a=1") == 1
    # assert clone_first_pair.("a=1&") == 1
    # assert clone_first_pair.("a=1&&") == 1
    # assert clone_first_pair.("a=1&b=2") == 2
    # assert clone_first_pair.("a=1&&b=2") == 2
    # assert clone_first_pair.("a=1&&b=2&") == 2
    # assert clone_first_pair.("a=1&&b=2&&") == 2
  end
end
