const utf8Encoder = new TextEncoder();
const utf8Decoder = new TextDecoder();

export class MemoryIO {
  constructor(exports) {
    this.memoryBytes = new Uint8Array(exports.memory.buffer);
    this.alloc = exports.alloc;
  }
  
  readString(ptr) {
    const { memoryBytes } = this;
    
    // Search for null-terminating byte.
    const endPtr = memoryBytes.indexOf(0, ptr);
    // Get subsection of memory between start and end, and decode it as UTF-8.
    return utf8Decoder.decode(memoryBytes.subarray(ptr, endPtr));
  }
  
  writeStringAt(stringValue, memoryOffset) {
    const { memoryBytes } = this;
    
    stringValue = stringValue.toString();
    const bytes = utf8Encoder.encode(stringValue);
    utf8Encoder.encodeInto(stringValue, memoryBytes.subarray(memoryOffset));
    memoryBytes[memoryOffset + bytes.length] = 0x0;
    return bytes.byteLength;
  }

  writeString(stringValue) {
    const { memoryBytes, alloc } = this;
    
    stringValue = stringValue.toString();
    const bytes = utf8Encoder.encode(stringValue);
    const strPtr = alloc(bytes.length + 1);
    utf8Encoder.encodeInto(stringValue, memoryBytes.subarray(strPtr));
    memoryBytes[strPtr + bytes.length] = 0x0;
    return Object.freeze([strPtr, bytes.byteLength]);
  }
}
