(module
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func))
  (type (;2;) (func (result i32)))
  (type (;3;) (func (param i32 i32) (result i32)))
  (type (;4;) (func (param i32)))
  (type (;5;) (func (param i32 i32)))
  (func (;0;) (type 0) (param i32) (result i32)
    (local i32)
    global.get 0
    global.get 0
    local.get 0
    i32.add
    global.set 0)
  (func (;1;) (type 1)
    global.get 2
    i32.eqz
    if  ;; label = @1
      global.get 0
      global.set 1
    end
    global.get 2
    i32.const 1
    i32.add
    global.set 2)
  (func (;2;) (type 2) (result i32)
    global.get 2
    i32.eqz
    if  ;; label = @1
      unreachable
    end
    global.get 2
    i32.const 1
    i32.sub
    global.set 2
    global.get 2
    i32.eqz
    if  ;; label = @1
      global.get 0
      i32.const 0
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
    end
    global.get 1)
  (func (;3;) (type 1)
    i32.const 65536
    global.set 0)
  (func (;4;) (type 0) (param i32) (result i32)
    (local i32 i32 i32)
    loop  ;; label = @1
      local.get 0
      i32.load8_u
      local.tee 1
      i32.eqz
      local.get 1
      i32.const 38
      i32.eq
      i32.or
      if (result i32)  ;; label = @2
        local.get 3
        local.get 2
        i32.const 0
        i32.ne
        i32.add
        local.set 3
        i32.const 0
      else
        local.get 2
        i32.const 1
        i32.add
      end
      local.set 2
      local.get 0
      i32.const 1
      i32.add
      local.set 0
      local.get 1
      br_if 0 (;@1;)
    end
    local.get 3)
  (func (;5;) (type 0) (param i32) (result i32)
    (local i32)
    loop (result i32)  ;; label = @1
      local.get 0
      i32.load8_u
      local.tee 1
      i32.eqz
      if  ;; label = @2
        i32.const 1
        return
      end
      local.get 1
      i32.const 38
      i32.ne
      if (result i32)  ;; label = @2
        i32.const 0
      else
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        br 1 (;@1;)
      end
    end)
  (func (;6;) (type 0) (param i32) (result i32)
    (local i32 i32)
    call 1
    loop (result i32)  ;; label = @1
      local.get 0
      i32.load8_u
      local.tee 1
      i32.eqz
      local.get 1
      i32.const 38
      i32.eq
      local.get 2
      i32.const 0
      i32.ne
      i32.and
      i32.or
      if (result i32)  ;; label = @2
        call 2
      else
        local.get 1
        i32.const 38
        i32.ne
        if  ;; label = @3
          global.get 0
          local.get 1
          i32.store8
          global.get 0
          i32.const 1
          i32.add
          global.set 0
          local.get 2
          i32.const 1
          i32.add
          local.set 2
        end
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        br 1 (;@1;)
      end
    end)
  (func (;7;) (type 0) (param i32) (result i32)
    (local i32 i32)
    loop (result i32)  ;; label = @1
      local.get 0
      i32.load8_u
      local.tee 2
      i32.eqz
      local.get 2
      i32.const 38
      i32.eq
      local.get 1
      i32.const 0
      i32.ne
      i32.and
      i32.or
      if (result i32)  ;; label = @2
        local.get 0
      else
        local.get 1
        i32.const 1
        i32.add
        local.get 1
        local.get 2
        i32.const 38
        i32.ne
        select
        local.set 1
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        br 1 (;@1;)
      end
    end)
  (func (;8;) (type 3) (param i32 i32) (result i32)
    i32.const 0)
  (func (;9;) (type 0) (param i32) (result i32)
    (local i32 i32)
    loop (result i32)  ;; label = @1
      local.get 0
      i32.load8_u
      local.tee 1
      i32.eqz
      local.get 1
      i32.const 38
      i32.eq
      local.get 2
      i32.const 0
      i32.ne
      i32.and
      i32.or
      if  ;; label = @2
        i32.const 0
        return
      end
      local.get 1
      i32.const 61
      i32.eq
      if (result i32)  ;; label = @2
        local.get 0
        i32.const 1
        i32.add
        local.tee 1
        i32.load8_u
        local.set 0
        i32.const 0
        local.get 1
        local.get 0
        i32.eqz
        local.get 0
        i32.const 38
        i32.eq
        i32.or
        select
      else
        local.get 2
        i32.const 1
        i32.add
        local.get 2
        local.get 1
        i32.const 38
        i32.ne
        select
        local.set 2
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        br 1 (;@1;)
      end
    end)
  (func (;10;) (type 0) (param i32) (result i32)
    (local i32)
    i32.const 3
    i32.const 1
    local.get 0
    i32.load8_u
    i32.const 37
    i32.eq
    select
    local.get 0
    i32.add
    local.tee 1
    i32.load8_u
    local.set 0
    i32.const 0
    local.get 1
    local.get 0
    i32.eqz
    local.get 0
    i32.const 38
    i32.eq
    i32.or
    select)
  (func (;11;) (type 0) (param i32) (result i32)
    (local i32 i32)
    call 1
    loop  ;; label = @1
      local.get 0
      i32.load8_u
      local.tee 1
      if  ;; label = @2
        local.get 1
        i32.const 57
        i32.le_u
        local.get 1
        i32.const 48
        i32.ge_u
        i32.and
        local.get 1
        i32.const 122
        i32.le_u
        local.get 1
        i32.const 97
        i32.ge_u
        i32.and
        local.get 1
        i32.const 90
        i32.le_u
        local.get 1
        i32.const 65
        i32.ge_u
        i32.and
        i32.or
        i32.or
        local.get 1
        i32.const 43
        i32.eq
        local.get 1
        i32.const 58
        i32.eq
        i32.or
        local.get 1
        i32.const 47
        i32.eq
        i32.or
        local.get 1
        i32.const 63
        i32.eq
        i32.or
        local.get 1
        i32.const 35
        i32.eq
        i32.or
        local.get 1
        i32.const 91
        i32.eq
        i32.or
        local.get 1
        i32.const 93
        i32.eq
        i32.or
        local.get 1
        i32.const 64
        i32.eq
        i32.or
        local.get 1
        i32.const 33
        i32.eq
        i32.or
        local.get 1
        i32.const 36
        i32.eq
        i32.or
        local.get 1
        i32.const 38
        i32.eq
        i32.or
        local.get 1
        i32.const 92
        i32.eq
        i32.or
        local.get 1
        i32.const 39
        i32.eq
        i32.or
        local.get 1
        i32.const 40
        i32.eq
        i32.or
        local.get 1
        i32.const 41
        i32.eq
        i32.or
        local.get 1
        i32.const 42
        i32.eq
        i32.or
        local.get 1
        i32.const 44
        i32.eq
        i32.or
        local.get 1
        i32.const 59
        i32.eq
        i32.or
        local.get 1
        i32.const 61
        i32.eq
        i32.or
        local.get 1
        i32.const 126
        i32.eq
        i32.or
        local.get 1
        i32.const 95
        i32.eq
        i32.or
        local.get 1
        i32.const 45
        i32.eq
        i32.or
        local.get 1
        i32.const 46
        i32.eq
        i32.or
        i32.or
        if  ;; label = @3
          global.get 0
          local.get 1
          i32.store8
        else
          global.get 0
          i32.const 37
          i32.store8
          global.get 0
          i32.const 1
          i32.add
          global.set 0
          global.get 0
          local.get 1
          i32.const 4
          i32.shr_u
          local.tee 2
          i32.const 48
          i32.const 55
          local.get 2
          i32.const 9
          i32.le_u
          select
          i32.add
          i32.store8
          global.get 0
          i32.const 1
          i32.add
          global.set 0
          global.get 0
          local.get 1
          i32.const 15
          i32.and
          local.tee 1
          i32.const 48
          i32.const 55
          local.get 1
          i32.const 9
          i32.le_u
          select
          i32.add
          i32.store8
        end
        global.get 0
        i32.const 1
        i32.add
        global.set 0
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        br 1 (;@1;)
      end
    end
    call 2)
  (func (;12;) (type 4) (param i32)
    (local i32 i32)
    loop  ;; label = @1
      local.get 0
      i32.load8_u
      local.tee 1
      if  ;; label = @2
        local.get 1
        i32.const 32
        i32.eq
        if  ;; label = @3
          global.get 0
          i32.const 43
          i32.store8
        else
          local.get 1
          i32.const 57
          i32.le_u
          local.get 1
          i32.const 48
          i32.ge_u
          i32.and
          local.get 1
          i32.const 122
          i32.le_u
          local.get 1
          i32.const 97
          i32.ge_u
          i32.and
          local.get 1
          i32.const 90
          i32.le_u
          local.get 1
          i32.const 65
          i32.ge_u
          i32.and
          i32.or
          i32.or
          local.get 1
          i32.const 126
          i32.eq
          local.get 1
          i32.const 95
          i32.eq
          i32.or
          local.get 1
          i32.const 45
          i32.eq
          i32.or
          local.get 1
          i32.const 46
          i32.eq
          i32.or
          i32.or
          if  ;; label = @4
            global.get 0
            local.get 1
            i32.store8
          else
            global.get 0
            i32.const 37
            i32.store8
            global.get 0
            i32.const 1
            i32.add
            global.set 0
            global.get 0
            local.get 1
            i32.const 4
            i32.shr_u
            local.tee 2
            i32.const 48
            i32.const 55
            local.get 2
            i32.const 9
            i32.le_u
            select
            i32.add
            i32.store8
            global.get 0
            i32.const 1
            i32.add
            global.set 0
            global.get 0
            local.get 1
            i32.const 15
            i32.and
            local.tee 1
            i32.const 48
            i32.const 55
            local.get 1
            i32.const 9
            i32.le_u
            select
            i32.add
            i32.store8
          end
        end
        global.get 0
        i32.const 1
        i32.add
        global.set 0
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        br 1 (;@1;)
      end
    end)
  (func (;13;) (type 5) (param i32 i32)
    global.get 0
    i32.const 38
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    local.get 0
    call 12
    global.get 0
    i32.const 61
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    local.get 1
    call 12)
  (func (;14;) (type 0) (param i32) (result i32)
    call 1
    local.get 0
    call 12
    call 2)
  (func (;15;) (type 0) (param i32) (result i32)
    (local i32)
    local.get 0
    i32.load8_u
    local.tee 1
    i32.eqz
    if  ;; label = @1
      i32.const 0
      return
    end
    block (result i32)  ;; label = @1
      local.get 1
      i32.const 37
      i32.eq
      if  ;; label = @2
        local.get 0
        i32.const 1
        i32.add
        i32.load8_u
        local.tee 1
        if (result i32)  ;; label = @3
          local.get 0
          i32.const 2
          i32.add
          i32.load8_u
          local.tee 0
          i32.const 6
          i32.shr_u
          i32.const 9
          i32.mul
          local.get 0
          i32.const 15
          i32.and
          i32.add
          local.get 1
          i32.const 6
          i32.shr_u
          i32.const 9
          i32.mul
          local.get 1
          i32.const 15
          i32.and
          i32.add
          i32.const 4
          i32.shl
          i32.add
        else
          i32.const 0
        end
        br 1 (;@1;)
      end
      local.get 1
    end)
  (memory (;0;) 2)
  (global (;0;) (mut i32) (i32.const 65536))
  (global (;1;) (mut i32) (i32.const 0))
  (global (;2;) (mut i32) (i32.const 0))
  (export "memory" (memory 0))
  (export "free_all" (func 3))
  (export "alloc" (func 0))
  (export "url_encoded_count" (func 4))
  (export "url_encoded_empty?" (func 5))
  (export "url_encoded_clone_first" (func 6))
  (export "url_encoded_rest" (func 7))
  (export "url_encoded_decode_first_value_www_form" (func 8))
  (export "url_encoded_first_value_offset" (func 9))
  (export "_url_encoded_value_next_char" (func 10))
  (export "url_encode_rfc3986" (func 11))
  (export "append_url_encode_www_form" (func 12))
  (export "append_url_encode_query_pair_www_form" (func 13))
  (export "url_encode_www_form" (func 14))
  (export "decode_char_www_form" (func 15)))
