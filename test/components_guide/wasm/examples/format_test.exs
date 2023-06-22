defmodule ComponentsGuide.Wasm.Examples.Format.Test do
  use ExUnit.Case, async: true

  alias ComponentsGuide.Wasm
  alias ComponentsGuide.Wasm.Instance
  alias ComponentsGuide.Wasm.Examples.Format

  describe "IntToString" do
    alias Format.IntToString

    test "u32toa_count" do
      assert Wasm.call(IntToString, :u32toa_count, 0) == 1
      assert Wasm.call(IntToString, :u32toa_count, 7) == 1
      assert Wasm.call(IntToString, :u32toa_count, 17) == 2
      assert Wasm.call(IntToString, :u32toa_count, 173) == 3
      assert Wasm.call(IntToString, :u32toa_count, 604_800) == 6
    end
  end

  describe "URLEncoding" do
    alias Format.URLEncoding

    test "wasm byte size" do
      assert byte_size(Wasm.to_wasm(URLEncoding)) == 866
    end

    test "url_encode_rfc3986" do
      inst = Instance.run(URLEncoding)
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

      assert url_encode.(":/?#[]@!$&\'()*+,;=~_-.") == ":/?#[]@!$&\'()*+,;=~_-."
      assert url_encode.("😀") == "%F0%9F%98%80"
      assert url_encode.("💪🏾") == "%F0%9F%92%AA%F0%9F%8F%BE"
    end

    test "url_encode_www_form" do
      inst = Instance.run(URLEncoding)
      url_encode = Instance.capture(inst, String, :url_encode_www_form, 1)

      assert url_encode.("0123456789") == "0123456789"
      assert url_encode.("abcxyzABCXYZ") == "abcxyzABCXYZ"
      assert url_encode.("two words") == "two+words"
      assert url_encode.("TWO WORDS") == "TWO+WORDS"
      # assert url_encode.("+") == "%60"
      # assert url_encode.("`") == "%60"
      # assert url_encode.("<>`") == "%3C%3E%60"
      # assert url_encode.("put it+й") == "put%20it+%D0%B9"
      # 
      # assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
      #          "ftp://s-ite.tld/?value=put%20it+%D0%B9"
      # 
      # assert url_encode.(":/?#[]@!$&\'()*+,;=~_-.") == ":/?#[]@!$&\'()*+,;=~_-."
      # assert url_encode.("😀") == "%F0%9F%98%80"
      # assert url_encode.("💪🏾") == "%F0%9F%92%AA%F0%9F%8F%BE"
    end

    # @tag :skip
    test "opt" do
      path_wasm = Path.join(__DIR__, "url_encode.wasm")
      path_wat = Path.join(__DIR__, "url_encode.wat")
      path_opt_wasm = Path.join(__DIR__, "url_encode_OPT.wasm")
      path_opt_wat = Path.join(__DIR__, "url_encode_OPT.wat")
      wasm = Wasm.to_wasm(URLEncoding)
      File.write!(path_wasm, wasm)
      System.cmd("wasm-opt", [path_wasm, "-o", path_opt_wasm, "-O"])

      %{size: size} = File.stat!(path_opt_wasm)
      assert size == 771

      {wat, 0} = System.cmd("wasm2wat", [path_wasm])
      File.write!(path_wat, wat)
      {opt_wat, 0} = System.cmd("wasm2wat", [path_opt_wasm])
      File.write!(path_opt_wat, opt_wat)
    end
  end

  # byte_size(Wasm.to_wasm(URLEncoding)) |> dbg()
end
