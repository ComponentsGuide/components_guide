// See: https://hansihe.com/posts/rustler-safe-erlang-elixir-nifs-in-rust/

pub mod atom;

use std::convert::{TryFrom, TryInto};
use std::ffi::CStr;
use std::time::Duration;
// use std::rc::Rc;
use anyhow::anyhow;
use crossbeam_channel::bounded;
use std::slice;
use std::sync::{Arc, RwLock};
use std::thread;
// use log::{info, warn};
use wasmtime::*;
//use anyhow::Error as anyhowError;
use rustler::{
    nif, Atom, Binary, Encoder, Env, Error, LocalPid, NewBinary, NifRecord, NifStruct,
    NifTaggedEnum, NifTuple, NifUnitEnum, OwnedBinary, OwnedEnv, ResourceArc, Term,
};
use wabt::Wat2Wasm;

#[nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[nif]
fn reverse_string(a: String) -> String {
    // return a;
    return a.chars().rev().collect();
}

fn string_error<T: ToString>(error: T) -> Error {
    return Error::Term(Box::new(error.to_string()));
}

fn map_return_values_i32(env: Env, values: Vec<u32>) -> Term {
    match values[..] {
        [] => rustler::types::atom::nil().encode(env),
        [a] => a.encode(env),
        [a, b] => (a, b).encode(env),
        [a, b, c] => (a, b, c).encode(env),
        [a, b, c, d] => (a, b, c, d).encode(env),
        [..] => values.encode(env),
    }
}

#[derive(NifTaggedEnum)]
enum WasmModuleDefinition<'a> {
    Wat(String),
    Wasm(Binary<'a>),
}

// #[derive(NifTuple)]
// struct WasmExport {
//     type: i32,
//     name: String,
// }

#[derive(Clone, NifUnitEnum)]
enum GlobalType {
    I32,
    I64,
    F32,
    F64,
}
impl TryFrom<wasmtime::ValType> for GlobalType {
    type Error = anyhow::Error;

    fn try_from(val: wasmtime::ValType) -> Result<Self, anyhow::Error> {
        Ok(match val {
            ValType::I32 => GlobalType::I32,
            ValType::I64 => GlobalType::I64,
            ValType::F32 => GlobalType::F32,
            ValType::F64 => GlobalType::F64,
            _ => anyhow::bail!("Unsupported global type {}", val),
        })
    }
}
// TODO: remove this one
impl TryFrom<&wasmtime::ValType> for GlobalType {
    type Error = anyhow::Error;

    fn try_from(val: &wasmtime::ValType) -> Result<Self, anyhow::Error> {
        Ok(match val {
            ValType::I32 => GlobalType::I32,
            ValType::I64 => GlobalType::I64,
            ValType::F32 => GlobalType::F32,
            ValType::F64 => GlobalType::F64,
            _ => anyhow::bail!("Unsupported global type {}", val),
        })
    }
}
impl From<GlobalType> for wasmtime::ValType {
    fn from(val: GlobalType) -> wasmtime::ValType {
        match val {
            GlobalType::I32 => ValType::I32,
            GlobalType::I64 => ValType::I64,
            GlobalType::F32 => ValType::F32,
            GlobalType::F64 => ValType::F64,
        }
    }
}

#[derive(NifTaggedEnum)]
enum WasmExternType {
    Func {
        params: Vec<GlobalType>,
        results: Vec<GlobalType>,
    },
    // Func(GlobalType),
    Global(GlobalType),
    Memory(),
    Table(),
    // Baz{ a: i32, b: i32 },
}

impl TryFrom<ExternType> for WasmExternType {
    type Error = anyhow::Error;

    fn try_from(val: ExternType) -> Result<Self, anyhow::Error> {
        Ok(match val {
            ExternType::Func(f) => {
                let params: Result<Vec<GlobalType>> =
                    f.params().into_iter().map(|p| p.try_into()).collect();
                let results: Result<Vec<GlobalType>> =
                    f.results().into_iter().map(|p| p.try_into()).collect();
                WasmExternType::Func {
                    params: params?,
                    results: results?,
                }
            }
            ExternType::Global(g) => WasmExternType::Global(g.content().try_into()?),
            ExternType::Memory(_m) => WasmExternType::Memory(),
            ExternType::Table(_t) => WasmExternType::Table(),
        })
    }
}

#[derive(NifTuple)]
struct WasmImport {
    module: String,
    name: String,
    extern_type: WasmExternType,
}

#[derive(NifTaggedEnum)]
enum WasmExport {
    Func(String),
    Global(String, GlobalType),
    Memory(String),
    Table(String),
    // Baz{ a: i32, b: i32 },
}

#[derive(NifTaggedEnum, Debug, Copy, Clone)]
enum WasmSupportedValue {
    I32(i32),
    I64(i64),
    F32(f32),
    F64(f64),
}

impl TryFrom<&wasmtime::Val> for WasmSupportedValue {
    type Error = anyhow::Error;

    fn try_from(val: &wasmtime::Val) -> Result<Self, anyhow::Error> {
        Ok(match val {
            Val::I32(i) => WasmSupportedValue::I32(*i),
            Val::I64(i) => WasmSupportedValue::I64(*i),
            Val::F32(f) => WasmSupportedValue::F32(val.unwrap_f32()),
            Val::F64(f) => WasmSupportedValue::F64(val.unwrap_f64()),
            val => anyhow::bail!("Unsupported val type {}", val.ty()),
        })
    }
}

impl Into<wasmtime::Val> for WasmSupportedValue {
    fn into(self) -> wasmtime::Val {
        match self {
            WasmSupportedValue::I32(i) => Val::I32(i),
            WasmSupportedValue::I64(i) => Val::I64(i),
            WasmSupportedValue::F32(f) => f.into(),
            WasmSupportedValue::F64(f) => f.into(),
        }
    }
}

impl AsRef<[u8]> for WasmModuleDefinition<'_> {
    fn as_ref(&self) -> &[u8] {
        match self {
            WasmModuleDefinition::Wat(s) => s.as_ref(),
            WasmModuleDefinition::Wasm(b) => &*b,
        }
    }
}

#[nif]
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

#[nif(schedule = "DirtyCpu")]
fn wasm_list_imports(source: WasmModuleDefinition) -> Result<Vec<WasmImport>, Error> {
    let engine = Engine::default();
    let module = Module::new(&engine, &source).map_err(string_error)?;
    let imports = module.imports();

    let imports: Result<Vec<WasmImport>, anyhow::Error> = imports
        .into_iter()
        .map(|import| {
            let module_name = import.module().to_string();
            let name = import.name().to_string();
            Ok(WasmImport {
                module: module_name,
                name: name,
                extern_type: import.ty().try_into()?,
            })
        })
        .collect();

    imports.map_err(string_error)
}

#[nif(schedule = "DirtyCpu")]
fn wasm_call_i32(wat_source: String, f: String, args: Vec<u32>) -> Result<Vec<u32>, Error> {
    let source = WasmModuleDefinition::Wat(wat_source);
    RunningInstance::new(source)
        .and_then(|mut i| i.call_i32(f, args))
        .map_err(string_error)
}

#[nif(schedule = "DirtyCpu")]
fn wasm_call(
    wat_source: String,
    f: String,
    args: Vec<WasmSupportedValue>,
) -> Result<Vec<WasmSupportedValue>, Error> {
    let source = WasmModuleDefinition::Wat(wat_source);
    RunningInstance::new(source)
        .and_then(|mut i| i.call(f, args))
        .map_err(string_error)
}

#[nif]
fn wasm_call_void(wat_source: String, f: String) -> Result<(), Error> {
    let source = WasmModuleDefinition::Wat(wat_source);
    RunningInstance::new(source)
        .and_then(|mut i| i.call_0(f))
        .map_err(string_error)
}

#[nif]
fn wasm_call_i32_string(wat_source: String, f: String, args: Vec<u32>) -> Result<String, Error> {
    let source = WasmModuleDefinition::Wat(wat_source);
    RunningInstance::new(source)
        .and_then(|mut i| i.call_i32_string(f, args))
        .map_err(string_error)
}

fn wasm_read_memory<T>(
    store: &Store<T>,
    memory: &Memory,
    start: u32,
    length: u32,
) -> Result<Vec<u8>, anyhow::Error> {
    let start: usize = start.try_into().unwrap();
    let length: usize = length.try_into().unwrap();

    let mut string_buffer: Vec<u8> = Vec::with_capacity(length);
    string_buffer.resize(length, 0);
    memory.read(&store, start, &mut string_buffer)?;
    return Ok(string_buffer);
}

fn wasm_extract_string(
    // store: &Store<T>,
    store: impl AsContext,
    memory: &Memory,
    result: Vec<u32>,
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
    Call(String, Vec<u32>),
    CallString(String, Vec<u32>),
    WriteStringNulTerminated(u32, String, bool),
    ReadMemory(u32, u32),
    // Baz{ a: i32, b: i32 },
}

#[nif]
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
    args: Vec<u32>,
}

#[nif]
fn wasm_call_bulk(wat_source: String, calls: Vec<WasmBulkCall>) -> Result<Vec<Vec<u32>>, Error> {
    wasm_call_bulk_internal(wat_source, true, calls).map_err(string_error)
}

fn wasm_call_bulk_internal(
    wat_source: String,
    buffer: bool,
    calls: Vec<WasmBulkCall>,
) -> Result<Vec<Vec<u32>>, anyhow::Error> {
    let mut running_instance = RunningInstance::new(WasmModuleDefinition::Wat(wat_source))?;

    let results: Result<Vec<_>, _> = calls
        .into_iter()
        .map(|call| running_instance.call_i32(call.f, call.args))
        .collect();

    return Ok(results?);
}

struct RunningInstanceResource {
    identifier: String,
    // lock: RwLock<RunningInstance>,
    lock: Arc<RwLock<RunningInstance>>,
}

impl RunningInstanceResource {
    fn new(identifier: String, running_instance: RunningInstance) -> Self {
        Self {
            identifier: identifier,
            // lock: RwLock::new(running_instance),
            lock: Arc::new(RwLock::new(running_instance)),
        }
    }
}

struct RunningInstance {
    store: Store<()>,
    memory: Memory,
    instance: Instance,
}

#[derive(Clone, NifStruct)]
#[module = "ComponentsGuide.Wasm.FuncImport"]
struct FuncImport {
    unique_id: i64,
    module_name: String,
    name: String,
    param_types: Vec<GlobalType>,
    result_types: Vec<GlobalType>,
}

impl TryInto<wasmtime::FuncType> for FuncImport {
    type Error = anyhow::Error;

    fn try_into(self) -> Result<wasmtime::FuncType, anyhow::Error> {
        let params: Vec<ValType> = self.param_types.into_iter().map(|t| t.into()).collect();
        let results: Vec<ValType> = self.result_types.into_iter().map(|t| t.into()).collect();

        Ok(FuncType::new(params, results))
    }
}

struct ImportsTable
// where T: Fn(&[Val], &mut [Val]) -> Result<()>,
{
    funcs: Vec<FuncImport>,
}

trait CallbackReceiver: Send + Sync + Clone + Copy {
    fn pid(self) -> Option<LocalPid>;
    // fn env(self) -> Option<Env>;
    fn receive(self, func_id: i64, params: &[Val], results: &mut [Val]) -> Result<()>;
}

#[derive(Clone, Copy)]
struct NoopCallbackReceiver {}
impl CallbackReceiver for NoopCallbackReceiver {
    fn pid(self) -> Option<LocalPid> {
        None
    }
    // fn env(self) -> Option<Env> {
    //     None
    // }
    fn receive(self, _func_id: i64, _params: &[Val], _results: &mut [Val]) -> Result<()> {
        // TODO: this should return an error "To use imported functions run an instance."
        // Do nothing
        Ok(())
    }
}

#[derive(Clone, Copy)]
struct EnvCallbackReceiver<'a> {
    env: Env<'a>,
    gen_pid: LocalPid,
}
impl<'a> CallbackReceiver for EnvCallbackReceiver<'a> {
    fn pid(self) -> Option<LocalPid> {
        // Some(self.env.pid())
        Some(self.gen_pid)
    }
    // fn env(self) -> Option<Env<'_>> {
    //     Some(self.env)
    // }
    fn receive(self, func_id: i64, params: &[Val], results: &mut [Val]) -> Result<()> {
        // TODO
        Ok(())
    }
}

unsafe impl<'a> Send for EnvCallbackReceiver<'a> {}
unsafe impl<'a> Sync for EnvCallbackReceiver<'a> {}
// impl Send for EnvCallbackReceiver {}

struct CallOutToFuncReply {
    // recv: std::sync::mpsc::Receiver<i32>,
    // lock: RwLock<Term>,
    func_id: i64,
    lock: RwLock<Option<OwnedBinary>>,
    // sender: crossbeam_channel::Sender<OwnedBinary>,
    sender: crossbeam_channel::Sender<u32>,
    // caller: Caller<'a, ()>,
    // caller: Arc<Caller<'_, ()>>,
    // caller: RwLock<Box<dyn AsContext<Data = ()>>>,
    // memory: Memory,
    // memory_ptr: Arc<*const u8>,
    memory_ptr: std::sync::atomic::AtomicPtr<u8>,
    memory_size: usize,
}
unsafe impl Send for CallOutToFuncReply {}

impl CallOutToFuncReply {
    fn new(func_id: i64, sender: crossbeam_channel::Sender<u32>, caller: Caller<()>, memory: Memory) -> Self {
        // Self { func_id: func_id, lock: RwLock::new(OwnedBinary::new(0)) }
        Self {
            func_id: func_id,
            lock: RwLock::new(None),
            sender: sender,
            memory_ptr: memory.data_ptr(&caller).into(),
            memory_size: memory.data_size(&caller)
        }
    }
}

impl ImportsTable {
    fn define<T: CallbackReceiver>(
        self,
        linker: &mut Linker<()>,
        callback_receiver: T,
    ) -> Result<()> {
        // let mut env = OwnedEnv::new();
        let rc = Arc::new(callback_receiver);

        for fi in self.funcs {
            let ft: FuncType = fi.clone().try_into()?;
            // let ft: FuncType = FuncType::new(vec![ValType::I32], vec![ValType::I32]);
            let func_id = fi.unique_id;

            // let r = rc.clone();
            let r = Arc::downgrade(&rc);
            let pid = callback_receiver.pid().unwrap();
            
            let func_module_name = Arc::new(fi.module_name.clone());
            let func_name = Arc::new(fi.name.clone());
            let func_module_name2 = Arc::new(fi.module_name.clone());
            let func_name2 = Arc::new(fi.name.clone());
            // let func_module_name = Arc::new(fi.module_name.as_str());
            // let func_name = Arc::new(fi.name.as_str());

            linker.func_new(
                &fi.module_name,
                &fi.name,
                ft,
                move |mut caller, params, results| {
                    // results[0] = Val::I32(42);
                    // eprintln!("Error: Could not complete task");

                    let result_count = results.len();

                    if result_count > 0 {
                        results[0] = Val::I32(42);
                    }
                    let mut owned_env = OwnedEnv::new();

                    // let (sender, recv) = bounded::<OwnedBinary>(1);
                    let (sender, recv) = bounded::<u32>(1);
                    
                    // let params2 = params.clone();
                    let params2: Result<Vec<WasmSupportedValue>> = params.iter().map(|v| v.try_into()).collect();
                    let params2 = params2.expect("Params could not be converted into supported values");
                    
                    // TODO: what if memory wasn’t exported? We shouldn’t *required* memory to use imports.
                    let memory = caller.get_export("memory").unwrap().into_memory().unwrap();
                    let reply = ResourceArc::new(CallOutToFuncReply::new(func_id, sender, caller, memory));

                    // let mut owned_env2 = owned_env.clone();
                    thread::spawn(move || {
                        let mut owned_env = OwnedEnv::new();
                        
                        // let reply = ResourceArc::new(CallOutToFuncReply::new(func_id, sender, caller, memory));
                        owned_env.run(|env| {
                            let func_module_name2 = "";
                            let func_name2 = "";
                            eprintln!("Sending :reply_to_func_call_out func#{func_id} {func_module_name2} {func_name2}");
                            env.send(
                                &pid,
                                (atom::reply_to_func_call_out(), func_id, reply, params2).encode(env),
                            );
                        });
                        // let reply_binary = recv.recv().expect("Did not write back reply value 1");
                        // let reply_binary = recv.recv_timeout(Duration::from_secs(5)).expect("Did not recv reply value in time");

                        // // let reply_binary2 = reply_binary
                        // //     .as_ref()
                        // //     .expect("Did not write back reply value 2");
                        // eprintln!("Got reply");
                        // // reply_binary2.to_vec()

                        // let number = owned_env.run(|env| {
                        //     let (term, _size) = env
                        //         .binary_to_term(reply_binary.as_ref())
                        //         .expect("Could not decode term");
                        //     let number: i32 = term.decode().expect("Not a i32");
                        //     number
                        // });
                        // number
                    });

                    let reply_binary = recv
                        .recv_timeout(Duration::from_secs(5))
                        .unwrap_or_else(|error| panic!("Did not recv reply value in time calling imported func {}.{}: {error:?}", func_module_name, func_name));
                        // .expect("Did not recv reply value in time");

                    // let reply_binary2 = reply_binary
                    //     .as_ref()
                    //     .expect("Did not write back reply value 2");
                    eprintln!("Got reply {reply_binary}");
                    // reply_binary2.to_vec()

                    let number = reply_binary;
                    
                    // let number = owned_env.run(|env| {
                    //     let (term, _size) = env
                    //         .binary_to_term(reply_binary.as_ref())
                    //         .expect("Could not decode term");
                    //     let number: u32 = term.decode().expect("Not a u32");
                    //     number
                    // });
                    

                    // let number = reply_value.join().expect("Thread failed.");

                    // let number = owned_env.run(|env| {
                    //     let reply_binary2 = reply_binary2.join().expect("Thread failed.");
                    //     let (term, _size) = env
                    //         .binary_to_term(reply_binary2.as_ref())
                    //         .expect("Could not decode term");
                    //     let number: i32 = term.decode().expect("Not a i32");
                    //     number
                    // });

                    // let mut owned_env = OwnedEnv::new();
                    // let env = owned_env.run(|env| env.clone());
                    // let reply_saved_term = reply_saved_term.join()?;
                    // let number: i32 = reply_term.decode()?;

                    if result_count > 0 {
                        results[0] = Val::I32(number as i32);
                    }
                    Ok(())

                    // receiver.receive(func_id, params, result)
                    // r.upgrade()
                    //     .expect("Still alive")
                    //     .receive(func_id, params, result)

                    // func.write().unwrap()(params, result)
                    // TODO
                    // env.send_and_clear(&pid, |env| {
                    //     (atom::call_exfn(), func_id, sval_vec_to_term(env, values)).encode(env)
                    // });
                    // Ok(())
                },
            )?;
            // linker.define(&store, fi.module_name, fi.name, memory)?;
        }
        Ok(())
    }
}

impl RunningInstance {
    fn new_with_imports<T: CallbackReceiver>(
        wat_source: WasmModuleDefinition,
        imports: ImportsTable,
        receiver: T,
    ) -> Result<Self, anyhow::Error> {
        let engine = Engine::default();
        // let engine = Engine::new(Config::new().async_support(true))?;
        let module = Module::new(&engine, &wat_source)?;

        // A `Store` is what will own instances, functions, globals, etc. All wasm
        // items are stored within a `Store`, and it's what we'll always be using to
        // interact with the wasm world. Custom data can be stored in stores but for
        // now we just use `()`.
        let mut store = Store::new(&engine, ());
        let mut linker = Linker::new(&engine);

        let has_exported_memory: bool = module.exports().any(|export| match export.ty() {
            ExternType::Memory(_) => true,
            _ => false,
        });

        // TODO: remove this and just rely on exported memory
        let mut imported_memory: Option<Memory> = match has_exported_memory {
            true => None,
            false => {
                let memory_ty = MemoryType::new(3, None);
                let memory = Memory::new(&mut store, memory_ty)?;
                linker.define(&store, "env", "buffer", memory)?;
                Some(memory)
            }
        };

        imports.define(&mut linker, receiver)?;

        let instance = linker.instantiate(&mut store, &module)?;

        let memory = imported_memory
            .or_else(|| instance.get_memory(&mut store, "memory"))
            .expect("Expected memory to be exported.");

        return Ok(Self {
            store: store,
            memory: memory,
            instance: instance,
        });
    }

    fn new(wat_source: WasmModuleDefinition) -> Result<Self, anyhow::Error> {
        let imports_table = ImportsTable {
            funcs: Vec::default(),
        };
        let noop = NoopCallbackReceiver {};
        Self::new_with_imports(wat_source, imports_table, noop)
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
        new_value: u32,
    ) -> Result<(), anyhow::Error> {
        let global = self
            .instance
            .get_global(&mut self.store, &global_name)
            .ok_or(anyhow!("{} was not an exported global", global_name))?;

        return global.set(&mut self.store, Val::I32(new_value as i32));
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

    fn call_i32(&mut self, f: String, args: Vec<u32>) -> Result<Vec<u32>, anyhow::Error> {
        let func = self
            .instance
            .get_func(&mut self.store, &f)
            .expect(&format!("{} was not an exported function", f));

        let func_type = func.ty(&self.store);
        let args: Vec<Val> = args.into_iter().map(|i| Val::I32(i as i32)).collect();

        let mut result: Vec<Val> = Vec::with_capacity(16);
        let result_length = func_type.results().len();
        result.resize(result_length, Val::I32(0));

        func.call(&mut self.store, &args, &mut result)?;

        let result: Vec<u32> = result.iter().map(|v| v.unwrap_i32() as u32).collect();
        return Ok(result);
    }

    fn call(
        &mut self,
        f: String,
        args: Vec<WasmSupportedValue>,
    ) -> Result<Vec<WasmSupportedValue>, anyhow::Error> {
        let func = self
            .instance
            .get_func(&mut self.store, &f)
            .expect(&format!("{} was not an exported function", f));

        let func_type = func.ty(&self.store);
        let args: Vec<Val> = args.into_iter().map(|v| v.into()).collect();

        let mut result: Vec<Val> = Vec::with_capacity(16);
        let result_length = func_type.results().len();
        result.resize(result_length, Val::I32(0));

        func.call(&mut self.store, &args, &mut result)?;

        let result: Result<Vec<WasmSupportedValue>> = result.iter().map(|v| v.try_into()).collect();
        result
    }

    fn call_i32_string(&mut self, f: String, args: Vec<u32>) -> Result<String, anyhow::Error> {
        let func = self
            .instance
            .get_func(&mut self.store, &f)
            .expect(&format!("{} was not an exported function", f));

        let func_type = func.ty(&self.store);
        let args: Vec<Val> = args.into_iter().map(|i| Val::I32(i as i32)).collect();

        let mut result: Vec<Val> = Vec::with_capacity(16);
        let result_length = func_type.results().len();
        result.resize(result_length, Val::I32(0));

        func.call(&mut self.store, &args, &mut result)?;

        let result: Vec<u32> = result.iter().map(|v| v.unwrap_i32() as u32).collect();
        let s = wasm_extract_string(&self.store, &self.memory, result)?;
        Ok(s)
    }
    
    // fn cast(
    //     &mut self,
    //     env: Env,
    //     f: String,
    //     args: Vec<WasmSupportedValue>,
    // ) -> Result<(), anyhow::Error> {
    //     env.send_and_clear(&pid, |thread_env| {
    //         let func = self
    //             .instance
    //             .get_func(&mut self.store, &f)
    //             .expect(&format!("{} was not an exported function", f));
    //         
    //         let func_type = func.ty(&self.store);
    //         let args: Vec<Val> = args.into_iter().map(|v| v.into()).collect();
    //         
    //         let mut result: Vec<Val> = Vec::with_capacity(16);
    //         let result_length = func_type.results().len();
    //         result.resize(result_length, Val::I32(0));
    //         
    //         func.call(&mut self.store, &args, &mut result)?;
    //         
    //         let result: Result<Vec<WasmSupportedValue>> = result.iter().map(|v| v.try_into()).collect();
    //         let result = result?;
    //         
    //         (atom::reply_to_func_cast(), f, result).encode(thread_env)
    //     });
    //     
    //     Ok(())
    // }

    fn write_i32(&mut self, memory_offset: u32, value: u32) -> Result<(), anyhow::Error> {
        let offset: usize = memory_offset.try_into().unwrap();
        let bytes = value.to_le_bytes();
        self.memory.write(&mut self.store, offset, &bytes)?;
        Ok(())
    }

    fn write_i64(&mut self, memory_offset: u32, value: u64) -> Result<(), anyhow::Error> {
        let offset: usize = memory_offset.try_into().unwrap();
        let bytes = value.to_le_bytes();
        self.memory.write(&mut self.store, offset, &bytes)?;
        Ok(())
    }

    fn write_string_nul_terminated(
        &mut self,
        memory_offset: u32,
        string: String,
    ) -> Result<i32, anyhow::Error> {
        let offset: usize = memory_offset.try_into().unwrap();
        // let mut bytes = string.as_bytes().clone();
        let mut bytes = string.as_bytes().to_vec();
        // let mut s = string.clone();
        // let vec = s.as_mut_vec();
        bytes.push(0);
        self.memory.write(&mut self.store, offset, &bytes)?;
        Ok(bytes.len().try_into().unwrap())
    }

    fn read_memory(&self, start: u32, length: u32) -> Result<Vec<u8>, anyhow::Error> {
        wasm_read_memory(&self.store, &self.memory, start, length)
    }
    
    fn read_string_nul_terminated(&self, start: u32) -> Result<String, anyhow::Error> {
        let s = wasm_extract_string(&self.store, &self.memory, vec![start])?;
        Ok(s)
    }
}

#[nif]
fn wasm_run_instance(
    env: Env,
    source: WasmModuleDefinition,
    identifier: String,
    func_imports: Vec<FuncImport>,
    gen_pid: LocalPid,
) -> Result<ResourceArc<RunningInstanceResource>, Error> {
    env.send(&env.pid(), atom::run_instance_start().encode(env));
    let imports_table = ImportsTable {
        funcs: func_imports,
    };
    let receiver = EnvCallbackReceiver {
        env: env,
        gen_pid: gen_pid,
    };
    let running_instance =
        RunningInstance::new_with_imports(source, imports_table, receiver).map_err(string_error)?;

    // info!("running_instance: {}", running_instance);

    let resource = ResourceArc::new(RunningInstanceResource::new(identifier, running_instance));

    Ok(resource)
}

#[nif]
fn wasm_instance_get_global_i32(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    global_name: String,
) -> Result<i32, Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance
        .get_global_value_i32(global_name)
        .map_err(string_error)?;

    Ok(result)
}

#[nif]
fn wasm_instance_set_global_i32(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    global_name: String,
    new_value: u32,
) -> Result<(), Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance
        .set_global_value_i32(global_name, new_value)
        .map_err(string_error)?;

    return Ok(result);
}

#[nif(schedule = "DirtyCpu")]
fn wasm_instance_call_func(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
) -> Result<(), Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance.call_0(f).map_err(string_error)?;

    return Ok(result);
}

#[nif(schedule = "DirtyCpu")]
fn wasm_instance_call_func_i32(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
    args: Vec<u32>,
) -> Result<Term, Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance.call_i32(f, args).map_err(string_error)?;
    return Ok(map_return_values_i32(env, result));
}

#[nif(schedule = "DirtyCpu")]
fn wasm_instance_call_func_i32_string(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
    args: Vec<u32>,
) -> Result<String, Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    return instance.call_i32_string(f, args).map_err(string_error);
}

#[nif]
fn wasm_instance_cast_func_i32(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    f: String,
    args: Vec<u32>,
) -> Result<(), Error> {
    eprintln!("CAST! {f}");
    // let c_lock = Arc::clone(&resource.lock);
    
    thread::spawn(move || {
        eprintln!("CAST in thread!");
        let mut instance = resource.lock.write().expect("Could not get a hold of resource.");
        eprintln!("Got instance");
        // let mut instance = c_lock.write().expect("Could not get a hold of resource.");
        let result = instance.call_i32(f, args).expect("WebAssembly call failed.");
        eprintln!("CAST call done!");
        // return Ok(map_return_values_i32(env, result));
    });
    
    Ok(())
}

#[nif]
fn wasm_instance_write_i32(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    memory_offset: u32,
    value: u32,
) -> Result<(), Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    instance
        .write_i32(memory_offset, value)
        .map_err(string_error)
}

#[nif]
fn wasm_instance_write_i64(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    memory_offset: u32,
    value: u64,
) -> Result<(), Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    instance
        .write_i64(memory_offset, value)
        .map_err(string_error)
}

#[nif]
fn wasm_instance_write_string_nul_terminated(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    memory_offset: u32,
    string: String,
) -> Result<i32, Error> {
    let mut instance = resource.lock.write().map_err(string_error)?;
    let result = instance
        .write_string_nul_terminated(memory_offset, string)
        .map_err(string_error)?;

    return Ok(result);
}

#[nif]
fn wasm_instance_read_memory(
    resource: ResourceArc<RunningInstanceResource>,
    start: u32,
    length: u32,
) -> Result<Vec<u8>, Error> {
    eprintln!("wasm_instance_read_memory");
    // let instance = resource.lock.read().map_err(string_error)?;
    let instance = resource.lock.try_read().map_err(string_error)?;
    let result = instance.read_memory(start, length).map_err(string_error)?;

    return Ok(result);
}

#[nif(schedule = "DirtyCpu")]
fn wasm_instance_read_string_nul_terminated(
    env: Env,
    resource: ResourceArc<RunningInstanceResource>,
    memory_offset: u32
) -> Result<String, Error> {
    eprintln!("wasm_instance_read_string_nul_terminated");
    // drop(resource.lock.try_read().map_err(string_error)?);
    
    let mut instance = resource.lock.try_write().map_err(string_error)?;
    let result = instance
        .read_string_nul_terminated(memory_offset)
        .map_err(string_error)?;

    return Ok(result);
}

#[nif]
fn wasm_call_out_reply(
    env: Env,
    resource: ResourceArc<CallOutToFuncReply>,
    reply: u32,
    // reply: Term,
) -> Result<(), Error> {
    // let mut binary = resource.lock.write().map_err(string_error)?;
    // *binary = Some(reply.to_binary());
    
    eprintln!("Received reply in Rust! {reply}");

    resource
        .sender
        .send(reply)
        .map_err(string_error)?;

    return Ok(());
}

#[nif]
fn wasm_caller_read_string_nul_terminated(
    env: Env,
    resource: ResourceArc<CallOutToFuncReply>,
    memory_offset: u32
    // reply: Term,
) -> Result<String, Error> {
    let memory_ptr = &resource.memory_ptr;
    let memory_size = resource.memory_size;
    eprintln!("wasm_caller_read_string_nul_terminated {memory_size}");
    
    let memory_ptr = memory_ptr.load(std::sync::atomic::Ordering::Relaxed);
    // let data = &memory.data(&store)[start..];
    let data: &[i8] =
        unsafe { slice::from_raw_parts(memory_ptr as *const i8, memory_size) };
    
    let memory_offset: usize = memory_offset.try_into().unwrap();
    let data = &data[memory_offset..];
    
    let cstr = unsafe { CStr::from_ptr(data.as_ptr()) };
    let string = String::from_utf8_lossy(cstr.to_bytes()).to_string();
    
    eprintln!("wasm_caller_read_string_nul_terminated {string}");
    
    // let s = wasm_extract_string(&caller, &memory, vec![memory_offset])?;

    return Ok(string);
}

// The `'a` in this function definition is something called a lifetime.
// This will inform the Rust compiler of how long different things are
// allowed to live. Don't worry too much about this, as this will be the
// exact same for most function definitions.
fn load<'a>(env: Env<'a>, _load_info: Term<'a>) -> bool {
    // This macro will take care of defining and initializing a new resource
    // object type.
    rustler::resource!(RunningInstanceResource, env);
    rustler::resource!(CallOutToFuncReply, env);
    true
}

#[nif(schedule = "DirtyCpu")]
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
        }
        Err(e) => Err(string_error(e)),
    };
}

#[nif(schedule = "DirtyCpu")]
// #[nif]
fn validate_module_definition(env: Env, source: WasmModuleDefinition) -> Result<(), Error> {
    let module = match source {
        WasmModuleDefinition::Wat(s) => {
            let s = s.clone();
            let source: &[u8] = s.as_ref();
            wabt::Module::parse_wat("hello.wat", source, wabt::Features::new())
        }
        WasmModuleDefinition::Wasm(b) => {
            wabt::Module::read_binary(b.as_ref(), &wabt::ReadBinaryOptions::default())
        }
    }
    .map_err(string_error)?;

    let result = module.validate().map_err(string_error);
    result
    // Ok(())
}

rustler::init!(
    "Elixir.ComponentsGuide.Wasm.WasmNative",
    [
        add,
        reverse_string,
        wasm_list_exports,
        wasm_list_imports,
        wasm_call_i32,
        wasm_call,
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
        wasm_instance_cast_func_i32,
        wasm_instance_write_i32,
        wasm_instance_write_i64,
        wasm_instance_write_string_nul_terminated,
        wasm_instance_read_memory,
        wasm_instance_read_string_nul_terminated,
        wasm_call_out_reply,
        wasm_caller_read_string_nul_terminated,
        wat2wasm,
        validate_module_definition
    ],
    load = load
);
