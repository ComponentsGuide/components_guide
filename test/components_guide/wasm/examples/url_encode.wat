(module
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func (param i32 i32 i32)))
  (type (;2;) (func (param i32 i32) (result i32)))
  (type (;3;) (func))
  (type (;4;) (func (result i32)))
  (type (;5;) (func (param i32)))
  (type (;6;) (func (param i32 i32)))
  (func (;0;) (type 0) (param i32) (result i32)
    global.get 0
    global.get 0
    local.get 0
    i32.add
    global.set 0)
  (func (;1;) (type 1) (param i32 i32 i32)
    (local i32)
    loop  ;; label = @1
      local.get 3
      local.get 2
      i32.eq
      if  ;; label = @2
        return
      end
      local.get 0
      local.get 3
      i32.add
      local.get 1
      local.get 3
      i32.add
      i32.load8_u
      i32.store8
      local.get 3
      i32.const 1
      i32.add
      local.set 3
      br 0 (;@1;)
    end)
  (func (;2;) (type 1) (param i32 i32 i32)
    (local i32)
    loop  ;; label = @1
      local.get 3
      local.get 2
      i32.eq
      if  ;; label = @2
        return
      end
      local.get 0
      local.get 3
      i32.add
      local.get 1
      i32.store8
      local.get 3
      i32.const 1
      i32.add
      local.set 3
      br 0 (;@1;)
    end)
  (func (;3;) (type 2) (param i32 i32) (result i32)
    (local i32 i32 i32)
    loop (result i32)  ;; label = @1
      local.get 0
      local.get 2
      i32.add
      i32.load8_u
      local.set 3
      local.get 1
      local.get 2
      i32.add
      i32.load8_u
      local.set 4
      local.get 3
      i32.eqz
      if  ;; label = @2
        local.get 4
        i32.eqz
        return
      end
      local.get 3
      local.get 4
      i32.eq
      if  ;; label = @2
        local.get 2
        i32.const 1
        i32.add
        local.set 2
        br 1 (;@1;)
      end
      i32.const 0
      return
    end)
  (func (;4;) (type 0) (param i32) (result i32)
    (local i32)
    loop  ;; label = @1
      local.get 0
      local.get 1
      i32.add
      i32.load8_u
      if  ;; label = @2
        local.get 1
        i32.const 1
        i32.add
        local.set 1
        br 1 (;@1;)
      end
    end
    local.get 1)
  (func (;5;) (type 0) (param i32) (result i32)
    (local i32 i32)
    loop  ;; label = @1
      local.get 1
      i32.const 1
      i32.add
      local.set 1
      local.get 0
      i32.const 10
      i32.rem_u
      local.set 2
      local.get 0
      i32.const 10
      i32.div_u
      local.set 0
      local.get 0
      i32.const 0
      i32.gt_u
      br_if 0 (;@1;)
    end
    local.get 1)
  (func (;6;) (type 2) (param i32 i32) (result i32)
    (local i32 i32 i32)
    local.get 1
    local.get 0
    call 5
    i32.add
    local.set 3
    local.get 3
    local.set 2
    loop  ;; label = @1
      local.get 2
      i32.const 1
      i32.sub
      local.set 2
      local.get 0
      i32.const 10
      i32.rem_u
      local.set 4
      local.get 0
      i32.const 10
      i32.div_u
      local.set 0
      local.get 2
      i32.const 48
      local.get 4
      i32.add
      i32.store8
      local.get 0
      i32.const 0
      i32.gt_u
      br_if 0 (;@1;)
    end
    local.get 3)
  (func (;7;) (type 3)
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
  (func (;8;) (type 4) (result i32)
    global.get 2
    i32.const 0
    i32.gt_u
    if  ;; label = @1
      nop
    else
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
  (func (;9;) (type 5) (param i32)
    (local i32)
    local.get 0
    global.get 1
    i32.eq
    if  ;; label = @1
      return
    end
    local.get 0
    call 4
    local.set 1
    global.get 0
    local.get 0
    local.get 1
    call 1
    global.get 0
    local.get 1
    i32.add
    global.set 0)
  (func (;10;) (type 4) (result i32)
    global.get 0
    global.get 1
    i32.gt_u)
  (func (;11;) (type 3)
    i32.const 65536
    global.set 0)
  (func (;12;) (type 0) (param i32) (result i32)
    (local i32 i32 i32)
    loop  ;; label = @1
      local.get 0
      i32.load8_u
      local.set 1
      local.get 1
      i32.const 38
      i32.eq
      local.get 1
      i32.eqz
      i32.or
      if  ;; label = @2
        local.get 2
        local.get 3
        i32.const 0
        i32.gt_u
        i32.add
        local.set 2
        i32.const 0
        local.set 3
      else
        local.get 3
        i32.const 1
        i32.add
        local.set 3
      end
      local.get 0
      i32.const 1
      i32.add
      local.set 0
      local.get 1
      br_if 0 (;@1;)
    end
    local.get 2)
  (func (;13;) (type 0) (param i32) (result i32)
    (local i32 i32)
    loop (result i32)  ;; label = @1
      local.get 0
      i32.load8_u
      local.set 1
      local.get 1
      i32.eqz
      if  ;; label = @2
        i32.const 1
        return
      end
      local.get 1
      i32.const 38
      i32.eq
      i32.eqz
      if  ;; label = @2
        i32.const 0
        return
      end
      local.get 0
      i32.const 1
      i32.add
      local.set 0
      br 0 (;@1;)
    end)
  (func (;14;) (type 0) (param i32) (result i32)
    (local i32 i32)
    call 7
    loop (result i32)  ;; label = @1
      local.get 0
      i32.load8_u
      local.set 1
      local.get 1
      i32.eqz
      local.get 1
      i32.const 38
      i32.eq
      local.get 2
      i32.const 0
      i32.gt_u
      i32.and
      i32.or
      if  ;; label = @2
        call 8
        return
      end
      local.get 1
      i32.const 38
      i32.eq
      i32.eqz
      if  ;; label = @2
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
      br 0 (;@1;)
    end)
  (func (;15;) (type 0) (param i32) (result i32)
    (local i32 i32)
    loop (result i32)  ;; label = @1
      local.get 0
      i32.load8_u
      local.set 1
      local.get 1
      i32.eqz
      local.get 1
      i32.const 38
      i32.eq
      local.get 2
      i32.const 0
      i32.gt_u
      i32.and
      i32.or
      if  ;; label = @2
        local.get 0
        return
      end
      local.get 1
      i32.const 38
      i32.eq
      i32.eqz
      if  ;; label = @2
        local.get 2
        i32.const 1
        i32.add
        local.set 2
      end
      local.get 0
      i32.const 1
      i32.add
      local.set 0
      br 0 (;@1;)
    end)
  (func (;16;) (type 2) (param i32 i32) (result i32)
    i32.const 0)
  (func (;17;) (type 0) (param i32) (result i32)
    (local i32 i32)
    loop (result i32)  ;; label = @1
      local.get 0
      i32.load8_u
      local.set 1
      local.get 1
      i32.eqz
      local.get 1
      i32.const 38
      i32.eq
      local.get 2
      i32.const 0
      i32.gt_u
      i32.and
      i32.or
      if  ;; label = @2
        i32.const 0
        return
      end
      local.get 1
      i32.const 61
      i32.eq
      if  ;; label = @2
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        local.get 0
        i32.load8_u
        local.set 1
        local.get 1
        i32.eqz
        local.get 1
        i32.const 38
        i32.eq
        i32.or
        if (result i32)  ;; label = @3
          i32.const 0
        else
          local.get 0
        end
        return
      end
      local.get 1
      i32.const 38
      i32.eq
      i32.eqz
      if  ;; label = @2
        local.get 2
        i32.const 1
        i32.add
        local.set 2
      end
      local.get 0
      i32.const 1
      i32.add
      local.set 0
      br 0 (;@1;)
    end)
  (func (;18;) (type 0) (param i32) (result i32)
    (local i32 i32)
    local.get 0
    i32.load8_u
    i32.const 37
    i32.eq
    if (result i32)  ;; label = @1
      i32.const 3
    else
      i32.const 1
    end
    local.get 0
    i32.add
    local.set 1
    local.get 1
    i32.load8_u
    local.set 2
    local.get 2
    i32.eqz
    local.get 2
    i32.const 38
    i32.eq
    i32.or
    if (result i32)  ;; label = @1
      i32.const 0
    else
      local.get 1
    end)
  (func (;19;) (type 0) (param i32) (result i32)
    (local i32 i32 i32)
    call 7
    loop  ;; label = @1
      local.get 0
      i32.load8_u
      local.set 1
      local.get 1
      if  ;; label = @2
        local.get 1
        i32.const 97
        i32.ge_u
        local.get 1
        i32.const 122
        i32.le_u
        i32.and
        local.get 1
        i32.const 65
        i32.ge_u
        local.get 1
        i32.const 90
        i32.le_u
        i32.and
        i32.or
        local.get 1
        i32.const 48
        i32.ge_u
        local.get 1
        i32.const 57
        i32.le_u
        i32.and
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
          global.get 0
          i32.const 1
          i32.add
          global.set 0
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
          local.get 1
          i32.const 4
          i32.shr_u
          i32.const 9
          i32.le_u
          if (result i32)  ;; label = @4
            i32.const 48
          else
            i32.const 65
            i32.const 10
            i32.sub
          end
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
          local.get 1
          i32.const 15
          i32.and
          i32.const 9
          i32.le_u
          if (result i32)  ;; label = @4
            i32.const 48
          else
            i32.const 65
            i32.const 10
            i32.sub
          end
          i32.add
          i32.store8
          global.get 0
          i32.const 1
          i32.add
          global.set 0
        end
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        br 1 (;@1;)
      end
    end
    call 8)
  (func (;20;) (type 5) (param i32)
    (local i32 i32 i32)
    loop  ;; label = @1
      local.get 0
      i32.load8_u
      local.set 1
      local.get 1
      if  ;; label = @2
        local.get 1
        i32.const 32
        i32.eq
        if  ;; label = @3
          global.get 0
          i32.const 43
          i32.store8
          global.get 0
          i32.const 1
          i32.add
          global.set 0
        else
          local.get 1
          i32.const 97
          i32.ge_u
          local.get 1
          i32.const 122
          i32.le_u
          i32.and
          local.get 1
          i32.const 65
          i32.ge_u
          local.get 1
          i32.const 90
          i32.le_u
          i32.and
          i32.or
          local.get 1
          i32.const 48
          i32.ge_u
          local.get 1
          i32.const 57
          i32.le_u
          i32.and
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
            global.get 0
            i32.const 1
            i32.add
            global.set 0
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
            local.get 1
            i32.const 4
            i32.shr_u
            i32.const 9
            i32.le_u
            if (result i32)  ;; label = @5
              i32.const 48
            else
              i32.const 65
              i32.const 10
              i32.sub
            end
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
            local.get 1
            i32.const 15
            i32.and
            i32.const 9
            i32.le_u
            if (result i32)  ;; label = @5
              i32.const 48
            else
              i32.const 65
              i32.const 10
              i32.sub
            end
            i32.add
            i32.store8
            global.get 0
            i32.const 1
            i32.add
            global.set 0
          end
        end
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        br 1 (;@1;)
      end
    end)
  (func (;21;) (type 6) (param i32 i32)
    global.get 0
    i32.const 38
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    local.get 0
    call 20
    global.get 0
    i32.const 61
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    local.get 1
    call 20)
  (func (;22;) (type 0) (param i32) (result i32)
    (local i32 i32 i32)
    call 7
    local.get 0
    call 20
    call 8)
  (func (;23;) (type 0) (param i32) (result i32)
    (local i32 i32 i32)
    local.get 0
    i32.load8_u
    local.set 1
    local.get 1
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
        local.set 2
        local.get 2
        i32.eqz
        if (result i32)  ;; label = @3
          i32.const 0
        else
          local.get 0
          i32.const 2
          i32.add
          i32.load8_u
          local.set 3
          local.get 2
          i32.const 15
          i32.and
          local.get 2
          i32.const 6
          i32.shr_u
          i32.const 9
          i32.mul
          i32.add
          i32.const 4
          i32.shl
          local.get 3
          i32.const 15
          i32.and
          local.get 3
          i32.const 6
          i32.shr_u
          i32.const 9
          i32.mul
          i32.add
          i32.add
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
  (export "free_all" (func 11))
  (export "alloc" (func 0))
  (export "url_encoded_count" (func 12))
  (export "url_encoded_empty?" (func 13))
  (export "url_encoded_clone_first" (func 14))
  (export "url_encoded_rest" (func 15))
  (export "url_encoded_decode_first_value_www_form" (func 16))
  (export "url_encoded_first_value_offset" (func 17))
  (export "_url_encoded_value_next_char" (func 18))
  (export "url_encode_rfc3986" (func 19))
  (export "append_url_encode_www_form" (func 20))
  (export "append_url_encode_query_pair_www_form" (func 21))
  (export "url_encode_www_form" (func 22))
  (export "decode_char_www_form" (func 23)))
