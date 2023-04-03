// See: https://hansihe.com/posts/rustler-safe-erlang-elixir-nifs-in-rust/

use anyhow::anyhow;
// use log::{info, warn};
use wasmtime::*;
//use anyhow::Error as anyhowError;
use rustler::{
    Atom, Binary, Encoder, Env, Error, NifRecord, NifStruct, NifTaggedEnum, NifTuple, ResourceArc,
    Term,
};
use std::convert::TryInto;
use std::ffi::CStr;
use std::slice;
use std::sync::RwLock;
use wabt::Wat2Wasm;

#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif]
fn reverse_string(a: String) -> String {
    // return a;
    return a.chars().rev().collect();
}

fn error_from(error: anyhow::Error) -> Error {
    return Error::Term(Box::new(error.to_string()));
}
fn string_error<T: ToString>(error: T) -> Error {
    return Error::Term(Box::new(error.to_string()));
}

// #[derive(NifTuple)]
// struct WasmExport {
//     type: i32,
//     name: String,
// }

#[derive(NifTaggedEnum)]
enum WasmExport {
    Func(String),
    Global(String),
    Memory(String),
    Table(String),
    // Baz{ a: i32, b: i32 },
}

#[derive(NifTaggedEnum)]
enum WasmModuleDefinition<'a> {
    Wat(String),
    Wasm(Binary<'a>),
}

impl AsRef<[u8]> for WasmModuleDefinition<'_> {
    fn as_ref(&self) -> &[u8] {
        match self {
            WasmModuleDefinition::Wat(s) => s.as_ref(),
            WasmModuleDefinition::Wasm(b) => &*b,
        }
    }
}

#[rustler::nif]
fn wasm_list_exports(source: WasmModuleDefinition) -> Result<Vec<WasmExport>, Error> {
    // fn wasm_list_exports(source: String) -> Result<Vec<WasmExport>, Error> {
    let engine = Engine::default();
    let module = Module::new(&engine, &source).map_err(string_error)?;
    let exports = module.exports();

    let exports: Vec<WasmExport> = exports
        .into_iter()
        .map(|export| {
            let name = export.name().to_string();
            return match export.ty() {
                ExternType::Func(_f) => WasmExport::Func(name),
                ExternType::Global(_g) => WasmExport::Global(name),
                ExternType::Memory(_m) => WasmExport::Memory(name),
                ExternType::Table(_t) => WasmExport::Table(name),
            };
        })
        .collect();

    return Ok(exports);
}

#[rustler::nif]
fn wasm_example_n_i32(source: String, f: String, args: Vec<i32>) -> Result<Vec<i32>, Error> {
    // return Ok(5);
    //return Err(Error::Term(Box::new("hello")));
    return match wasm_example_n_i32_internal(source, true, f, args) {
        Ok(v) => Ok(v),
        Err(e) => Err(string_error(e)),
    };
}

#[rustler::nif]
fn wasm_example_0(source: String, f: String) -> Result<i32, Error> {
    // return Ok(5);
    //return Err(Error::Term(Box::new("hello")));
    return match wasm_example_0_internal(source, f) {
        Ok(v) => Ok(v),
        Err(e) => Err(string_error(e)),
    };
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
fn wasm_string_i32(wat_source: String, f: String, args: Vec<i32>) -> Result<String, Error> {
    return match wasm_example_i32_string_internal(wat_source, f, args) {
        Ok(v) => Ok(v),
        Err(e) => Err(string_error(e)),
    };
}

fn wasm_read_memory<T>(
    store: &Store<T>,
    memory: &Memory,
    start: i32,
    length: i32,
) -> Result<Vec<u8>, anyhow::Error> {
    let start: usize = start.try_into().unwrap();
    let length: usize = length.try_into().unwrap();

    let mut string_buffer: Vec<u8> = Vec::with_capacity(length);
    string_buffer.resize(length, 0);
    memory.read(&store, start, &mut string_buffer)?;
    return Ok(string_buffer);
}

fn wasm_extract_string<T>(
    store: &mut Store<T>,
    memory: &Memory,
    result: Vec<i32>,
) -> Result<String, anyhow::Error> {
    match result.as_slice() {
        [] => anyhow::bail!("Receive empty result"),
        [start, length] => {
            let start = *start;
            let length = *length;
            let start: usize = start.try_into().unwrap();
            let length: usize = length.try_into().unwrap();

            let mut string_buffer: Vec<u8> = Vec::with_capacity(length);
            string_buffer.resize(length, 0);
            memory.read(&store, start, &mut string_buffer)?;
            let string = String::from_utf8(string_buffer)?;
            return Ok(string);
        }
        [start] => {
            let start = *start;
            let start: usize = start.try_into().unwrap();

            let data = &memory.data(&store)[start..];
            let data: &[i8] =
                unsafe { slice::from_raw_parts(data.as_ptr() as *const i8, data.len()) };

            let cstr = unsafe { CStr::from_ptr(data.as_ptr()) };
            let string = String::from_utf8_lossy(cstr.to_bytes()).to_string();

            return Ok(string);
        }
        _other_number_of_items => anyhow::bail!("Received result with too many items"),
    }
}

fn wasm_example_i32_string_internal(
    wat_source: String,
    f: String,
    args: Vec<i32>,
) -> Result<String, anyhow::Error> {
    let engine = Engine::default();

    // A `Store` is what will own instances, functions, globals, etc. All wasm
    // items are stored within a `Store`, and it's what we'll always be using to
    // interact with the wasm world. Custom data can be stored in stores but for
    // now we just use `()`.
    let mut store = Store::new(&engine, ());
    let mut linker = Linker::new(&engine);

    let memory_ty = MemoryType::new(2, None);
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

    let func_type = answer.ty(&store);
    // There's a few ways we can call the `answer` `Func` value. The easiest
    // is to statically assert its signature with `typed` (in this case
    // asserting it takes no arguments and returns one i32) and then call it.
    // let answer = answer.typed::<(i32, i32), i32>(&store)?;

    // let args = vec![a, b];
    // let args: &[Val] = &[Val::I32(a), Val::I32(b)];
    // let args: &[Val] = args.iter().map(|i| Val::I32(i)).collect();
    let args: Vec<Val> = args.into_iter().map(|i| Val::I32(i)).collect();

    let mut result: Vec<Val> = Vec::with_capacity(16);
    // result.resize(2, Val::I32(0));
    let result_length = func_type.results().len();
    result.resize(result_length, Val::I32(0));

    // And finally we can call our function! Note that the error propagation
    // with `?` is done to handle the case where the wasm function traps.
    answer.call(&mut store, &args, &mut result)?;

    let result: Vec<_> = result.iter().map(|v| v.unwrap_i32()).collect();

    match result.as_slice() {
        [] => anyhow::bail!("Receive empty result"),
        [start, length] => {
            let start = *start;
            let length = *length;
            let start: usize = start.try_into().unwrap();
            let length: usize = length.try_into().unwrap();

            let mut string_buffer: Vec<u8> = Vec::with_capacity(length);
            string_buffer.resize(length, 0);
            memory.read(&store, start, &mut string_buffer)?;
            let string = String::from_utf8(string_buffer)?;
            return Ok(string);
        }
        [start] => {
            let start = *start;
            let start: usize = start.try_into().unwrap();

            let data = &memory.data(&store)[start..];
            let data: &[i8] =
                unsafe { slice::from_raw_parts(data.as_ptr() as *const i8, data.len()) };

            let cstr = unsafe { CStr::from_ptr(data.as_ptr()) };
            let string = String::from_utf8_lossy(cstr.to_bytes()).to_string();

            return Ok(string);
        }
        _items => anyhow::bail!("Receive result with too many items"),
    }
}

fn wasm_example_n_i32_internal(
    wat_source: String,
    buffer: bool,
    f: String,
    args: Vec<i32>,
) -> Result<Vec<i32>, anyhow::Error> {
    let engine = Engine::default();

    // A `Store` is what will own instances, functions, globals, etc. All wasm
    // items are stored within a `Store`, and it's what we'll always be using to
    // interact with the wasm world. Custom data can be stored in stores but for
    // now we just use `()`.
    let mut store = Store::new(&engine, ());
    let mut linker = Linker::new(&engine);

    if buffer {
        let memory_ty = MemoryType::new(2, None);
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
    // let args: &[Val] = &[Val::I32(a), Val::I32(b)];
    // let args: &[Val] = args.iter().map(|i| Val::I32(i)).collect();
    let args: Vec<Val> = args.into_iter().map(|i| Val::I32(i)).collect();

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

#[derive(NifTaggedEnum)]
enum WasmStepInstruction {
    Call(String, Vec<i32>),
    CallString(String, Vec<i32>),
    WriteString(i32, String, bool),
    ReadMemory(i32, i32),
    // Baz{ a: i32, b: i32 },
}

#[rustler::nif]
fn wasm_steps(
    env: Env,
    wat_source: String,
    steps: Vec<WasmStepInstruction>,
) -> Result<Vec<Term>, Error> {
    return match wasm_steps_internal(env, wat_source, steps) {
        Ok(v) => Ok(v),
        Err(e) => Err(string_error(e)),
    };
}

fn wasm_steps_internal(
    env: Env,
    wat_source: String,
    steps: Vec<WasmStepInstruction>,
) -> Result<Vec<Term>, anyhow::Error> {
    let engine = Engine::default();

    // A `Store` is what will own instances, functions, globals, etc. All wasm
    // items are stored within a `Store`, and it's what we'll always be using to
    // interact with the wasm world. Custom data can be stored in stores but for
    // now we just use `()`.
    let mut store = Store::new(&engine, ());
    let mut linker = Linker::new(&engine);

    let memory_ty = MemoryType::new(2, None);
    let memory = Memory::new(&mut store, memory_ty)?;
    linker.define(&store, "env", "buffer", memory)?;

    let module = Module::new(&engine, wat_source)?;
    let instance = linker.instantiate(&mut store, &module)?;

    let mut results: Vec<Term> = Vec::with_capacity(steps.len());
    for step in steps {
        match step {
            WasmStepInstruction::Call(f, args) => {
                let func = instance
                    .get_func(&mut store, &f)
                    .expect(&format!("{} was not an exported function", f));

                let func_type = func.ty(&store);
                let args: Vec<Val> = args.into_iter().map(|i| Val::I32(i)).collect();

                let mut result: Vec<Val> = Vec::with_capacity(16);
                let result_length = func_type.results().len();
                result.resize(result_length, Val::I32(0));

                func.call(&mut store, &args, &mut result)?;

                let result: Vec<_> = result.iter().map(|v| v.unwrap_i32()).collect();
                match result[..] {
                    // [] => results.push(().encode(env)),
                    [] => results.push(rustler::types::atom::nil().encode(env)),
                    [a] => results.push(a.encode(env)),
                    [a, b] => results.push((a, b).encode(env)),
                    [a, b, c] => results.push((a, b, c).encode(env)),
                    [a, b, c, d] => results.push((a, b, c, d).encode(env)),
                    [..] => results.push(result.encode(env)),
                }
                // let result = result.collect_tuple()
                // let term = tuple.encode(env);
                // let term = result.encode(env);
                // results.push(term);
            }
            WasmStepInstruction::CallString(f, args) => {
                let func = instance
                    .get_func(&mut store, &f)
                    .ok_or(anyhow!("{} was not an exported function", f))?;
                // .ok_or(&format!("{} was not an exported function", f))?;

                let func_type = func.ty(&store);
                let args: Vec<Val> = args.into_iter().map(|i| Val::I32(i)).collect();

                let mut result: Vec<Val> = Vec::with_capacity(16);
                let result_length = func_type.results().len();
                result.resize(result_length, Val::I32(0));

                func.call(&mut store, &args, &mut result)?;

                let result: Vec<_> = result.iter().map(|v| v.unwrap_i32()).collect();

                let s = wasm_extract_string(&mut store, &memory, result)?;
                let term = s.encode(env);
                results.push(term);
            }
            WasmStepInstruction::WriteString(offset, string, null_terminated) => {
                // let mut slice = memory.data_mut(&mut store);
                // let bytes = s.into_bytes();
                // let bytes = s.as_bytes();
                let offset: usize = offset.try_into().unwrap();
                // let mut bytes = string.as_bytes().clone();
                let mut bytes = string.as_bytes().to_vec();
                // let mut s = string.clone();
                // let vec = s.as_mut_vec();
                if null_terminated {
                    bytes.push(0);
                }
                memory.write(&mut store, offset, &bytes)?;
                // let result = String::encode_utf8(slice);
                // slice[result.len()] = 0;
            }
            WasmStepInstruction::ReadMemory(start, length) => {
                let bytes = wasm_read_memory(&store, &memory, start, length)?;
                let term = bytes.encode(env);
                results.push(term);
            }
        };
    }

    return Ok(results);
}

#[derive(NifTuple)]
struct WasmBulkCall {
    f: String,
    args: Vec<i32>,
}

#[rustler::nif]
fn wasm_call_bulk(wat_source: String, calls: Vec<WasmBulkCall>) -> Result<Vec<Vec<i32>>, Error> {
    return match wasm_call_bulk_internal(wat_source, true, calls) {
        Ok(v) => Ok(v),
        Err(e) => Err(string_error(e)),
    };
}

fn wasm_call_bulk_internal(
    wat_source: String,
    buffer: bool,
    calls: Vec<WasmBulkCall>,
) -> Result<Vec<Vec<i32>>, anyhow::Error> {
    let engine = Engine::default();

    // A `Store` is what will own instances, functions, globals, etc. All wasm
    // items are stored within a `Store`, and it's what we'll always be using to
    // interact with the wasm world. Custom data can be stored in stores but for
    // now we just use `()`.
    let mut store = Store::new(&engine, ());
    let mut linker = Linker::new(&engine);

    if buffer {
        let memory_ty = MemoryType::new(2, None);
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

    let mut results: Vec<Vec<i32>> = Vec::with_capacity(calls.len());
    for call in calls {
        let func = instance
            .get_func(&mut store, &call.f)
            .expect(&format!("{} was not an exported function", call.f));

        let func_type = func.ty(&store);
        let args: Vec<Val> = call.args.into_iter().map(|i| Val::I32(i)).collect();

        let mut result: Vec<Val> = Vec::with_capacity(16);
        let result_length = func_type.results().len();
        result.resize(result_length, Val::I32(0));

        func.call(&mut store, &args, &mut result)?;

        let result: Vec<_> = result.iter().map(|v| v.unwrap_i32()).collect();

        results.push(result);
    }

    return Ok(results);
}

struct RunningInstanceResource {
    lock: RwLock<RunningInstance>,
}

struct RunningInstance {
    store: Store<()>,
    memory: Memory,
    instance: Instance,
}

impl RunningInstance {
    fn new(wat_source: WasmModuleDefinition) -> Result<Self, anyhow::Error> {
        let engine = Engine::default();

        // A `Store` is what will own instances, functions, globals, etc. All wasm
        // items are stored within a `Store`, and it's what we'll always be using to
        // interact with the wasm world. Custom data can be stored in stores but for
        // now we just use `()`.
        let mut store = Store::new(&engine, ());
        let mut linker = Linker::new(&engine);

        let memory_ty = MemoryType::new(2, None);
        let memory = Memory::new(&mut store, memory_ty)?;
        linker.define(&store, "env", "buffer", memory)?;

        let module = Module::new(&engine, &wat_source)?;
        let instance = linker.instantiate(&mut store, &module)?;

        return Ok(Self {
            store: store,
            memory: memory,
            instance: instance,
        });
    }

    fn call_0(&mut self, f: String) -> Result<i32, anyhow::Error> {
        let answer = self
            .instance
            .get_func(&mut self.store, &f)
            .expect(&format!("{} was not an exported function", f));

        let answer = answer.typed::<(), i32>(&mut self.store)?;
        let result = answer.call(&mut self.store, ())?;

        return Ok(result);
    }

    fn call_i32(&mut self, f: String, args: Vec<i32>) -> Result<Vec<i32>, anyhow::Error> {
        let func = self
            .instance
            .get_func(&mut self.store, &f)
            .expect(&format!("{} was not an exported function", f));

        let func_type = func.ty(&self.store);
        let args: Vec<Val> = args.into_iter().map(|i| Val::I32(i)).collect();

        let mut result: Vec<Val> = Vec::with_capacity(16);
        let result_length = func_type.results().len();
        result.resize(result_length, Val::I32(0));

        func.call(&mut self.store, &args, &mut result)?;

        let result: Vec<i32> = result.iter().map(|v| v.unwrap_i32()).collect();
        return Ok(result);
    }

    fn call_i32_string(&mut self, f: String, args: Vec<i32>) -> Result<String, anyhow::Error> {
        let func = self
            .instance
            .get_func(&mut self.store, &f)
            .expect(&format!("{} was not an exported function", f));

        let func_type = func.ty(&self.store);
        let args: Vec<Val> = args.into_iter().map(|i| Val::I32(i)).collect();

        let mut result: Vec<Val> = Vec::with_capacity(16);
        let result_length = func_type.results().len();
        result.resize(result_length, Val::I32(0));

        func.call(&mut self.store, &args, &mut result)?;

        let result: Vec<i32> = result.iter().map(|v| v.unwrap_i32()).collect();
        let s = wasm_extract_string(&mut self.store, &self.memory, result)?;
        return Ok(s);
    }

    fn write_string_nul_terminated(
        &mut self,
        memory_offset: i32,
        string: String,
    ) -> Result<i32, anyhow::Error> {
        let offset: usize = memory_offset.try_into().unwrap();
        // let mut bytes = string.as_bytes().clone();
        let mut bytes = string.as_bytes().to_vec();
        // let mut s = string.clone();
        // let vec = s.as_mut_vec();
        bytes.push(0);
        self.memory.write(&mut self.store, offset, &bytes)?;
        return Ok(bytes.len().try_into().unwrap());
    }

    fn read_memory(&self, start: i32, length: i32) -> Result<Vec<u8>, anyhow::Error> {
        return wasm_read_memory(&self.store, &self.memory, start, length);
    }
}

#[rustler::nif]
fn wasm_run_instance(
    env: Env,
    source: WasmModuleDefinition,
) -> Result<ResourceArc<RunningInstanceResource>, Error> {
    env.send(&env.pid(), env.error_tuple("running_instance"));
    let running_instance = RunningInstance::new(source).map_err(string_error)?;

    // info!("running_instance: {}", running_instance);

    let resource = ResourceArc::new(RunningInstanceResource {
        lock: RwLock::new(running_instance),
    });

    return Ok(resource);
}

#[rustler::nif]
fn wasm_instance_call_func(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
) -> Result<i32, Error> {
    // let mut instance = resource.lock.write().map_err(string_error)?;

    let mut instance = match resource.lock.write() {
        Ok(v) => Ok(v),
        Err(e) => Err(string_error(e)),
    }?;

    let result = instance.call_0(f).map_err(string_error)?;

    return Ok(result);
}

#[rustler::nif]
fn wasm_instance_call_func_i32(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
    args: Vec<i32>,
) -> Result<Term, Error> {
    // let mut instance = resource.lock.write().map_err(string_error)?;

    let mut instance = match resource.lock.write() {
        Ok(v) => Ok(v),
        Err(e) => Err(string_error(e)),
    }?;

    let result = instance.call_i32(f, args).map_err(string_error)?;

    return match result[..] {
        [] => Ok(rustler::types::atom::nil().encode(env)),
        [a] => Ok(a.encode(env)),
        [a, b] => Ok((a, b).encode(env)),
        [a, b, c] => Ok((a, b, c).encode(env)),
        [a, b, c, d] => Ok((a, b, c, d).encode(env)),
        [..] => Ok(result.encode(env)),
    };

    // return Ok(result);
}

#[rustler::nif]
fn wasm_instance_call_func_i32_string(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
    args: Vec<i32>,
) -> Result<String, Error> {
    // let mut instance = resource.lock.write().map_err(string_error)?;

    let mut instance = match resource.lock.write() {
        Ok(v) => Ok(v),
        Err(e) => Err(string_error(e)),
    }?;

    return instance.call_i32_string(f, args).map_err(string_error);
}

#[rustler::nif]
fn wasm_instance_write_string_nul_terminated(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    memory_offset: i32,
    string: String,
) -> Result<i32, Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance
        .write_string_nul_terminated(memory_offset, string)
        .map_err(string_error)?;

    return Ok(result);
}

#[rustler::nif]
fn wasm_instance_read_memory(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    start: i32,
    length: i32,
) -> Result<Vec<u8>, Error> {
    let instance = resource.lock.read().map_err(string_error)?;
    let result = instance.read_memory(start, length).map_err(string_error)?;

    return Ok(result);
}

// The `'a` in this function definition is something called a lifetime.
// This will inform the Rust compiler of how long different things are
// allowed to live. Don't worry too much about this, as this will be the
// exact same for most function definitions.
fn load<'a>(env: Env<'a>, _load_info: Term<'a>) -> bool {
    // This macro will take care of defining and initializing a new resource
    // object type.
    rustler::resource!(RunningInstanceResource, env);
    true
}

#[rustler::nif]
fn wat2wasm(wat_source: String) -> Result<Vec<u8>, Error> {
    let result = Wat2Wasm::new()
        // .canonicalize_lebs(true)
        // .write_debug_names(true)
        .convert(wat_source);

    return match result {
        Ok(v) => Ok(v.as_ref().to_vec()),
        Err(e) => Err(Error::Term(Box::new(e.to_string()))),
    };
}

rustler::init!(
    "Elixir.ComponentsGuide.Rustler.Wasm",
    [
        add,
        reverse_string,
        wasm_list_exports,
        wasm_example_n_i32,
        wasm_example_0,
        wasm_string_i32,
        wasm_call_bulk,
        wasm_steps,
        wasm_run_instance,
        wasm_instance_call_func,
        wasm_instance_call_func_i32,
        wasm_instance_call_func_i32_string,
        wasm_instance_write_string_nul_terminated,
        wasm_instance_read_memory,
        wat2wasm
    ],
    load = load
);
