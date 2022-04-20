#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif]
fn reverse_string(a: String) -> String {
  // return a;
    return a.chars().rev().collect();
}

rustler::init!("Elixir.ComponentsGuide.Rustler.Math", [add, reverse_string]);
