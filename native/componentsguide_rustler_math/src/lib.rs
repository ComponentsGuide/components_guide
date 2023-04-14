// See: https://hansihe.com/posts/rustler-safe-erlang-elixir-nifs-in-rust/

use anyhow::anyhow;
// use log::{info, warn};
use wasmtime::*;
//use anyhow::Error as anyhowError;
use rustler::{
    Atom, Binary, NewBinary, Encoder, Env, Error, NifRecord, NifStruct, NifUnitEnum, NifTaggedEnum, NifTuple, ResourceArc,
    Term,
};
use std::convert::{TryInto, TryFrom};
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

fn string_error<T: ToString>(error: T) -> Error {
    return Error::Term(Box::new(error.to_string()));
}

fn map_return_values_i32(env: Env, values: Vec<i32>) -> Term {
    match values[..] {
        [] => rustler::types::atom::nil().encode(env),
        [a] => a.encode(env),
        [a, b] => (a, b).encode(env),
        [a, b, c] => (a, b, c).encode(env),
        [a, b, c, d] => (a, b, c, d).encode(env),
        [..] => values.encode(env),
    }
}

// #[derive(NifTuple)]
// struct WasmExport {
//     type: i32,
//     name: String,
// }

#[derive(NifUnitEnum)]
enum GlobalType {
    I32,
    I64,
    F32,
    F64,
}
impl TryFrom<&wasmtime::ValType> for GlobalType {
    type Error = anyhow::Error;

    fn try_from(val: &wasmtime::ValType) -> Result<Self, anyhow::Error> {
        Ok(match val {
            ValType::I32 => GlobalType::I32,
            ValType::I64 => GlobalType::I64,
            ValType::F32 => GlobalType::F32,
            ValType::F64 => GlobalType::F64,
            _ => anyhow::bail!("Unsupported global type {}", val)
        })
    }
}

#[derive(NifTaggedEnum)]
enum WasmExport {
    Func(String),
    Global(String, GlobalType),
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
    let engine = Engine::default();
    let module = Module::new(&engine, &source).map_err(string_error)?;
    let exports = module.exports();

    let exports: Result<Vec<WasmExport>, anyhow::Error> = exports
        .into_iter()
        .map(|export| {
            let name = export.name().to_string();
            Ok(match export.ty() {
                ExternType::Func(_f) => WasmExport::Func(name),
                ExternType::Global(g) => WasmExport::Global(name, g.content().try_into()?),
                ExternType::Memory(_m) => WasmExport::Memory(name),
                ExternType::Table(_t) => WasmExport::Table(name),
            })
        })
        .collect();

    exports.map_err(string_error)
}

#[rustler::nif]
fn wasm_call_i32(wat_source: String, f: String, args: Vec<i32>) -> Result<Vec<i32>, Error> {
    let source = WasmModuleDefinition::Wat(wat_source);
    RunningInstance::new(source)
        .and_then(|mut i| i.call_i32(f, args))
        .map_err(string_error)
}

#[rustler::nif]
fn wasm_call_void(wat_source: String, f: String) -> Result<(), Error> {
    let source = WasmModuleDefinition::Wat(wat_source);
    RunningInstance::new(source)
        .and_then(|mut i| i.call_0(f))
        .map_err(string_error)
}

#[rustler::nif]
fn wasm_call_i32_string(wat_source: String, f: String, args: Vec<i32>) -> Result<String, Error> {
    let source = WasmModuleDefinition::Wat(wat_source);
    RunningInstance::new(source)
        .and_then(|mut i| i.call_i32_string(f, args))
        .map_err(string_error)
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

#[derive(NifTaggedEnum)]
enum WasmStepInstruction {
    Call(String, Vec<i32>),
    CallString(String, Vec<i32>),
    WriteStringNulTerminated(i32, String, bool),
    ReadMemory(i32, i32),
    // Baz{ a: i32, b: i32 },
}

#[rustler::nif]
fn wasm_steps(
    env: Env,
    wat_source: String,
    steps: Vec<WasmStepInstruction>,
) -> Result<Vec<Term>, Error> {
    wasm_steps_internal(env, wat_source, steps).map_err(string_error)
}

fn wasm_steps_internal(
    env: Env,
    wat_source: String,
    steps: Vec<WasmStepInstruction>,
) -> Result<Vec<Term>, anyhow::Error> {
    let mut running_instance = RunningInstance::new(WasmModuleDefinition::Wat(wat_source))?;

    let mut results: Vec<Term> = Vec::with_capacity(steps.len());
    for step in steps {
        match step {
            WasmStepInstruction::Call(f, args) => {
                let result = running_instance.call_i32(f, args)?;
                results.push(map_return_values_i32(env, result));
            }
            WasmStepInstruction::CallString(f, args) => {
                let string = running_instance.call_i32_string(f, args)?;
                results.push(string.encode(env));
            }
            WasmStepInstruction::WriteStringNulTerminated(offset, string, null_terminated) => {
                running_instance.write_string_nul_terminated(offset, string)?;
            }
            WasmStepInstruction::ReadMemory(start, length) => {
                let bytes = running_instance.read_memory(start, length)?;
                results.push(bytes.encode(env));
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
    wasm_call_bulk_internal(wat_source, true, calls).map_err(string_error)
}

fn wasm_call_bulk_internal(
    wat_source: String,
    buffer: bool,
    calls: Vec<WasmBulkCall>,
) -> Result<Vec<Vec<i32>>, anyhow::Error> {
    let mut running_instance = RunningInstance::new(WasmModuleDefinition::Wat(wat_source))?;

    let results: Result<Vec<_>, _> = calls
        .into_iter()
        .map(|call| running_instance.call_i32(call.f, call.args))
        .collect();

    return Ok(results?);
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

        let memory_ty = MemoryType::new(3, None);
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

    fn get_global_value_i32(&mut self, global_name: String) -> Result<i32, anyhow::Error> {
        let global_val = self
            .instance
            .get_global(&mut self.store, &global_name)
            .map(|g| g.get(&mut self.store));

        match global_val {
            Some(Val::I32(i)) => Ok(i),
            Some(other_val) => Err(anyhow!(
                "Only I32 globals are supported, got {} instead",
                other_val.ty()
            )),
            None => Err(anyhow!("{} was not an exported global", global_name)),
        }
    }

    fn set_global_value_i32(
        &mut self,
        global_name: String,
        new_value: i32,
    ) -> Result<(), anyhow::Error> {
        let global = self
            .instance
            .get_global(&mut self.store, &global_name)
            .ok_or(anyhow!("{} was not an exported global", global_name))?;

        return global.set(&mut self.store, Val::I32(new_value));
    }

    fn call_0(&mut self, f: String) -> Result<(), anyhow::Error> {
        let answer = self
            .instance
            .get_func(&mut self.store, &f)
            .expect(&format!("{} was not an exported function", f));

        // FIXME: this errs if the return type is not i32
        let answer = answer.typed::<(), ()>(&mut self.store)?;
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
fn wasm_instance_get_global_i32(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    global_name: String,
) -> Result<i32, Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance
        .get_global_value_i32(global_name)
        .map_err(string_error)?;

    return Ok(result);
}

#[rustler::nif]
fn wasm_instance_set_global_i32(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    global_name: String,
    new_value: i32,
) -> Result<(), Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance
        .set_global_value_i32(global_name, new_value)
        .map_err(string_error)?;

    return Ok(result);
}

#[rustler::nif]
fn wasm_instance_call_func(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
) -> Result<(), Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
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
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance.call_i32(f, args).map_err(string_error)?;
    return Ok(map_return_values_i32(env, result));
}

#[rustler::nif]
fn wasm_instance_call_func_i32_string(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
    args: Vec<i32>,
) -> Result<String, Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
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
// fn wat2wasm(wat_source: String) -> Result<Vec<u8>, Error> {
fn wat2wasm(env: Env, wat_source: String) -> Result<Binary, Error> {
    let result = Wat2Wasm::new()
        // .canonicalize_lebs(true)
        // .write_debug_names(true)
        .convert(wat_source);

    return match result {
        Ok(v) => {
            let v = v.as_ref();
            let mut b = NewBinary::new(env, v.len());
            b.as_mut_slice().copy_from_slice(v);
            let b2: Binary = b.into();
            Ok(b2)
        },
        Err(e) => Err(string_error(e)),
    };
}

rustler::init!(
    "Elixir.ComponentsGuide.Wasm.WasmNative",
    [
        add,
        reverse_string,
        wasm_list_exports,
        wasm_call_i32,
        wasm_call_void,
        wasm_call_i32_string,
        wasm_call_bulk,
        wasm_steps,
        wasm_run_instance,
        wasm_instance_get_global_i32,
        wasm_instance_set_global_i32,
        wasm_instance_call_func,
        wasm_instance_call_func_i32,
        wasm_instance_call_func_i32_string,
        wasm_instance_write_string_nul_terminated,
        wasm_instance_read_memory,
        wat2wasm
    ],
    load = load
);
