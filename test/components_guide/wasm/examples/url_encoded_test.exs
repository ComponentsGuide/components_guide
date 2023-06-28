defmodule ComponentsGuide.Wasm.Examples.URLEncoded.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.URLEncoded

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

  test "url_encode_rfc3986" do
    inst = Instance.run(URLEncoded)
    url_encode = Instance.capture(inst, String, :url_encode_rfc3986, 1)

    assert url_encode.("0123456789") == "0123456789"
    assert url_encode.("abcxyzABCXYZ") == "abcxyzABCXYZ"
    assert url_encode.("two words") == "two%20words"
    assert url_encode.("TWO WORDS") == "TWO%20WORDS"
    assert url_encode.("`") == "%60"
    assert url_encode.("<>`") == "%3C%3E%60"
    assert url_encode.("put it+й") == "put%20it+%D0%B9"

    assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
             "ftp://s-ite.tld/?value=put%20it+%D0%B9"

    assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
             URI.encode("ftp://s-ite.tld/?value=put it+й")

    assert url_encode.(":/?#[]@!$&\'()*+,;=~_-.") == ":/?#[]@!$&\'()*+,;=~_-."
    assert url_encode.(":/?#[]@!$&\'()*+,;=~_-.") == URI.encode(":/?#[]@!$&\'()*+,;=~_-.")

    assert url_encode.("😀") == "%F0%9F%98%80"
    assert url_encode.("💪🏾") == "%F0%9F%92%AA%F0%9F%8F%BE"
  end

  test "url_encode_www_form" do
    inst = Instance.run(URLEncoded)
    url_encode = Instance.capture(inst, String, :url_encode_www_form, 1)

    assert url_encode.("0123456789") == "0123456789"
    assert url_encode.("abcxyzABCXYZ") == "abcxyzABCXYZ"
    assert url_encode.("two words") == "two+words"
    assert url_encode.("TWO WORDS") == "TWO+WORDS"
    assert url_encode.("+") == "%2B"
    assert url_encode.("`") == "%60"
    assert url_encode.("<>`") == "%3C%3E%60"
    assert url_encode.("put it+й") == "put+it%2B%D0%B9"

    assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
             "ftp%3A%2F%2Fs-ite.tld%2F%3Fvalue%3Dput+it%2B%D0%B9"

    assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
             URI.encode_www_form("ftp://s-ite.tld/?value=put it+й")

    assert url_encode.(":/?#[]@!$&\'()*,;=~_-.") ==
             "%3A%2F%3F%23%5B%5D%40%21%24%26%27%28%29%2A%2C%3B%3D~_-."

    assert url_encode.(":/?#[]@!$&\'()*,;=~_-.") ==
             URI.encode_www_form(":/?#[]@!$&\'()*,;=~_-.")

    assert url_encode.("😀") == "%F0%9F%98%80"
    assert url_encode.("💪🏾") == "%F0%9F%92%AA%F0%9F%8F%BE"
  end

  @tag :skip
  test "append_url_encode_query_pair_www_form" do
    inst = Instance.run(URLEncoded)
    append_query = Instance.capture(inst, String, :append_url_encode_query_pair_www_form, 2)
    build_start = Instance.capture(inst, :bump_write_start, 0)
    build_done = Instance.capture(inst, String, :bump_write_done, 0)

    a = Instance.alloc_string("a")
    b = Instance.alloc_string("b")

    build_start.()
    append_query.(a, b)
    s = build_done.()

    assert s == "&a=b"
  end

  @tag :skip
  test "url_encode_query_www_form" do
    inst = Instance.run(URLEncoded)
    url_encode_query = Instance.capture(inst, String, :url_encode_query_www_form, 1)

    # {list, bytes, list_bytes} = Instance.alloc_list(inst, [["a", "1"], ["b", "2"]])
    # assert list == [[<<97, 0>>, <<49, 0>>], [<<98, 0>>, <<50, 0>>]]
    # assert bytes == <<97, 0, 49, 0, 98, 0, 50, 0>>
    # assert list_bytes == <<65540::little-size(32), 65552::little-size(32)>>
    list_ptr = Instance.alloc_list(inst, [["a", "1"], ["b", "2"]])
    assert url_encode_query.(list_ptr) == "a=1&b=2"

    # result = Instance.call(
    #   URLEncoded.url_encode_query_www_form([
    #     a: 1,
    #     b: 1,
    #   ])
    # )
  end

  @tag :skip
  test "wasm byte size" do
    assert byte_size(Wasm.to_wasm(URLEncoded)) == 1678
  end

  @tag :skip
  test "optimize with wasm-opt" do
    path_wasm = Path.join(__DIR__, "url_encode.wasm")
    path_wat = Path.join(__DIR__, "url_encode.wat")
    path_opt_wasm = Path.join(__DIR__, "url_encode_OPT.wasm")
    path_opt_wat = Path.join(__DIR__, "url_encode_OPT.wat")
    wasm = Wasm.to_wasm(URLEncoded)
    File.write!(path_wasm, wasm)
    System.cmd("wasm-opt", [path_wasm, "-o", path_opt_wasm, "-O"])

    %{size: size} = File.stat!(path_opt_wasm)
    assert size == 1222

    {wat, 0} = System.cmd("wasm2wat", [path_wasm])
    File.write!(path_wat, wat)
    {opt_wat, 0} = System.cmd("wasm2wat", [path_opt_wasm])
    File.write!(path_opt_wat, opt_wat)
  end
end
