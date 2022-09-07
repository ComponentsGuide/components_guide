Various cheatsheets will be added over time. If you have ideas for cheatsheets, please submit them.

<p>From Elixir: <%= 6 + 1 %></p>
<p>From Rust: <%= ComponentsGuide.Rustler.Math.add(5, 11) %></p>
<p>From Rust: <%= ComponentsGuide.Rustler.Math.reverse_string("hello") %></p>

<hr />

<h2>From WebAssembly + Rust</h2>
<pre class="language-wasm"><code><%= @wasm_constant %></code></pre>
<p><%= inspect(ComponentsGuide.Rustler.Math.wasm_example(@wasm_constant, "answer")) %></p>
