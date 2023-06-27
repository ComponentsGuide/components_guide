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
end
