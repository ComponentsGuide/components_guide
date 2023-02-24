use wasmtime::*;
//use anyhow::Error as anyhowError;
use rustler::{Atom, Env, Error, NifStruct, ResourceArc, Term};
use std::convert::TryInto;

#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif]
fn reverse_string(a: String) -> String {
    // return a;
    return a.chars().rev().collect();
}

#[rustler::nif]
fn wasm_example_0(source: String, f: String) -> Result<i32, Error> {
    // return Ok(5);
    //return Err(Error::Term(Box::new("hello")));
    return match wasm_example_0_internal(source, f) {
      Ok(v) => Ok(v),
      Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

fn wasm_example_0_internal(source: String, f: String) -> Result<i32, anyhow::Error> {
    let engine = Engine::default();

    // We start off by creating a `Module` which represents a compiled form
    // of our input wasm module. In this case it'll be JIT-compiled after
    // we parse the text format.
    let module = Module::new(&engine, source)?;

    // A `Store` is what will own instances, functions, globals, etc. All wasm
    // items are stored within a `Store`, and it's what we'll always be using to
    // interact with the wasm world. Custom data can be stored in stores but for
    // now we just use `()`.
    let mut store = Store::new(&engine, ());

    // With a compiled `Module` we can then instantiate it, creating
    // an `Instance` which we can actually poke at functions on.
    let instance = Instance::new(&mut store, &module, &[])?;

    // The `Instance` gives us access to various exported functions and items,
    // which we access here to pull out our `answer` exported function and
    // run it.
    let answer = instance
        .get_func(&mut store, &f)
        .expect(&format!("{} was not an exported function", f));

    // There's a few ways we can call the `answer` `Func` value. The easiest
    // is to statically assert its signature with `typed` (in this case
    // asserting it takes no arguments and returns one i32) and then call it.
    let answer = answer.typed::<(), i32>(&store)?;

    // And finally we can call our function! Note that the error propagation
    // with `?` is done to handle the case where the wasm function traps.
    let result = answer.call(&mut store, ())?;

    return Ok(result);
}

#[rustler::nif]
fn wasm_example_1_i32(source: String, f: String, a: i32) -> Result<i32, Error> {
    return match wasm_example_1_i32_internal(source, f, a) {
      Ok(v) => Ok(v),
      Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

fn wasm_example_1_i32_internal(source: String, f: String, a: i32) -> Result<i32, anyhow::Error> {
    let engine = Engine::default();

    // We start off by creating a `Module` which represents a compiled form
    // of our input wasm module. In this case it'll be JIT-compiled after
    // we parse the text format.
    let module = Module::new(&engine, source)?;

    // A `Store` is what will own instances, functions, globals, etc. All wasm
    // items are stored within a `Store`, and it's what we'll always be using to
    // interact with the wasm world. Custom data can be stored in stores but for
    // now we just use `()`.
    let mut store = Store::new(&engine, ());

    // With a compiled `Module` we can then instantiate it, creating
    // an `Instance` which we can actually poke at functions on.
    let instance = Instance::new(&mut store, &module, &[])?;

    // The `Instance` gives us access to various exported functions and items,
    // which we access here to pull out our `answer` exported function and
    // run it.
    let answer = instance
        .get_func(&mut store, &f)
        .expect(&format!("{} was not an exported function", f));

    // There's a few ways we can call the `answer` `Func` value. The easiest
    // is to statically assert its signature with `typed` (in this case
    // asserting it takes no arguments and returns one i32) and then call it.
    let answer = answer.typed::<i32, i32>(&store)?;

    // And finally we can call our function! Note that the error propagation
    // with `?` is done to handle the case where the wasm function traps.
    let result = answer.call(&mut store, a)?;

    return Ok(result);
}

#[rustler::nif]
fn wasm_example_2_i32(source: String, f: String, a: i32, b: i32) -> Result<i32, Error> {
    return match wasm_example_2_i32_internal(source, false, f, a, b) {
      Ok(v) => Ok(v),
      Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

#[rustler::nif]
fn wasm_buffer_2_i32(wat_source: String, f: String, a: i32, b: i32) -> Result<Vec<i32>, Error> {
    return match wasm_example_2_i32_n_internal(wat_source, true, f, a, b) {
      Ok(v) => Ok(v),
      Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

#[rustler::nif]
fn wasm_string_2_i32(wat_source: String, f: String, a: i32, b: i32) -> Result<String, Error> {
    return match wasm_example_2_i32_string_internal(wat_source, f, a, b) {
      Ok(v) => Ok(v),
      Err(e) => Err(Error::Term(Box::new(e.to_string())))
    }
}

fn wasm_example_2_i32_internal(wat_source: String, buffer: bool, f: String, a: i32, b: i32) -> Result<i32, anyhow::Error> {
    let engine = Engine::default();

    // A `Store` is what will own instances, functions, globals, etc. All wasm
    // items are stored within a `Store`, and it's what we'll always be using to
    // interact with the wasm world. Custom data can be stored in stores but for
    // now we just use `()`.
    let mut store = Store::new(&engine, ());
    let mut linker = Linker::new(&engine);

    if buffer {
      let memory_ty = MemoryType::new(1, None);
      let memory = Memory::new(&mut store, memory_ty)?;
      linker.define(&store, "env", "buffer", memory)?;
    }

    // We start off by creating a `Module` which represents a compiled form
    // of our input wasm module. In this case it'll be JIT-compiled after
    // we parse the text format.
    let module = Module::new(&engine, wat_source)?;
    
    // With a compiled `Module` we can then instantiate it, creating
    // an `Instance` which we can actually poke at functions on.
    // let instance = Instance::new(&mut store, &module, &[])?;
    let instance = linker.instantiate(&mut store, &module)?;

    // The `Instance` gives us access to various exported functions and items,
    // which we access here to pull out our `answer` exported function and
    // run it.
    let answer = instance
        .get_func(&mut store, &f)
        .expect(&format!("{} was not an exported function", f));

    // There's a few ways we can call the `answer` `Func` value. The easiest
    // is to statically assert its signature with `typed` (in this case
    // asserting it takes no arguments and returns one i32) and then call it.
    let answer = answer.typed::<(i32, i32), i32>(&store)?;

    // And finally we can call our function! Note that the error propagation
    // with `?` is done to handle the case where the wasm function traps.
    let result = answer.call(&mut store, (a, b))?;

    return Ok(result);
}

fn wasm_example_2_i32_n_internal(wat_source: String, buffer: bool, f: String, a: i32, b: i32) -> Result<Vec<i32>, anyhow::Error> {
    let engine = Engine::default();

    // A `Store` is what will own instances, functions, globals, etc. All wasm
    // items are stored within a `Store`, and it's what we'll always be using to
    // interact with the wasm world. Custom data can be stored in stores but for
    // now we just use `()`.
    let mut store = Store::new(&engine, ());
    let mut linker = Linker::new(&engine);

    if buffer {
      let memory_ty = MemoryType::new(1, None);
      let memory = Memory::new(&mut store, memory_ty)?;
      linker.define(&store, "env", "buffer", memory)?;
    }

    // We start off by creating a `Module` which represents a compiled form
    // of our input wasm module. In this case it'll be JIT-compiled after
    // we parse the text format.
    let module = Module::new(&engine, wat_source)?;
    
    // With a compiled `Module` we can then instantiate it, creating
    // an `Instance` which we can actually poke at functions on.
    // let instance = Instance::new(&mut store, &module, &[])?;
    let instance = linker.instantiate(&mut store, &module)?;

    // The `Instance` gives us access to various exported functions and items,
    // which we access here to pull out our `answer` exported function and
    // run it.
    let answer = instance
        .get_func(&mut store, &f)
        .expect(&format!("{} was not an exported function", f));

    let func_type = answer.ty(&store);
    // There's a few ways we can call the `answer` `Func` value. The easiest
    // is to statically assert its signature with `typed` (in this case
    // asserting it takes no arguments and returns one i32) and then call it.
    // let answer = answer.typed::<(i32, i32), i32>(&store)?;

    // let args = vec![a, b];
    let args: &[Val] = &[Val::I32(a), Val::I32(b)];

    let mut result: Vec<Val> = Vec::with_capacity(16);
    // result.resize(2, Val::I32(0));
    let result_length = func_type.results().len();
    result.resize(result_length, Val::I32(0));

    // And finally we can call our function! Note that the error propagation
    // with `?` is done to handle the case where the wasm function traps.
    answer.call(&mut store, &args, &mut result)?;

    let result: Vec<_> = result.iter().map(|v| v.unwrap_i32()).collect();

    return Ok(result);
}

fn wasm_example_2_i32_string_internal(wat_source: String, f: String, a: i32, b: i32) -> Result<String, anyhow::Error> {
  let engine = Engine::default();

  // A `Store` is what will own instances, functions, globals, etc. All wasm
  // items are stored within a `Store`, and it's what we'll always be using to
  // interact with the wasm world. Custom data can be stored in stores but for
  // now we just use `()`.
  let mut store = Store::new(&engine, ());
  let mut linker = Linker::new(&engine);

  let memory_ty = MemoryType::new(1, None);
  let memory = Memory::new(&mut store, memory_ty)?;
  linker.define(&store, "env", "buffer", memory)?;

  // We start off by creating a `Module` which represents a compiled form
  // of our input wasm module. In this case it'll be JIT-compiled after
  // we parse the text format.
  let module = Module::new(&engine, wat_source)?;
  
  // With a compiled `Module` we can then instantiate it, creating
  // an `Instance` which we can actually poke at functions on.
  // let instance = Instance::new(&mut store, &module, &[])?;
  let instance = linker.instantiate(&mut store, &module)?;

  // The `Instance` gives us access to various exported functions and items,
  // which we access here to pull out our `answer` exported function and
  // run it.
  let answer = instance
      .get_func(&mut store, &f)
      .expect(&format!("{} was not an exported function", f));

  // There's a few ways we can call the `answer` `Func` value. The easiest
  // is to statically assert its signature with `typed` (in this case
  // asserting it takes no arguments and returns one i32) and then call it.
  let answer = answer.typed::<(i32, i32), (i32, i32)>(&store)?;

  // And finally we can call our function! Note that the error propagation
  // with `?` is done to handle the case where the wasm function traps.
  let (start, length) = answer.call(&mut store, (a, b))?;
  let start: usize = start.try_into().unwrap();
  let length: usize = length.try_into().unwrap();

  let mut string_buffer: Vec<u8> = Vec::with_capacity(length);
  string_buffer.resize(length, 0);
  memory.read(&store, start, &mut string_buffer)?;
  let string = String::from_utf8(string_buffer)?;

  return Ok(string);
}

rustler::init!("Elixir.ComponentsGuide.Rustler.Math", [
  add,
  reverse_string,
  wasm_example_0,
  wasm_example_1_i32,
  wasm_example_2_i32,
  wasm_buffer_2_i32,
  wasm_string_2_i32
]);
