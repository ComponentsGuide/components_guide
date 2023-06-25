(module
  (type (;0;) (func (param i32 i32) (result i32)))
  (type (;1;) (func (param i32) (result i32)))
  (type (;2;) (func (param i32 i32 i32)))
  (func (;0;) (type 0) (param i32 i32) (result i32)
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
  (func (;1;) (type 1) (param i32) (result i32)
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
  (func (;2;) (type 1) (param i32) (result i32)
    global.get 0
    global.get 0
    local.get 0
    i32.add
    global.set 0)
  (func (;3;) (type 2) (param i32 i32 i32)
    (local i32)
    loop  ;; label = @1
      local.get 0
      local.get 3
      i32.add
      local.get 1
      local.get 3
      i32.add
      i32.load8_u
      i32.store8
      local.get 3
      local.get 2
      i32.lt_u
      if  ;; label = @2
        local.get 3
        i32.const 1
        i32.add
        local.set 3
        br 1 (;@1;)
      end
    end)
  (func (;4;) (type 1) (param i32) (result i32)
    (local i32 i32 i32)
    global.get 0
    global.set 1
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
            i32.const 55
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
            i32.const 55
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
    global.get 0
    i32.const 0
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 1)
  (func (;5;) (type 1) (param i32) (result i32)
    (local i32 i32 i32)
    global.get 0
    global.set 1
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
              i32.const 55
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
              i32.const 55
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
    end
    global.get 0
    i32.const 0
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 1)
  (func (;6;) (type 1) (param i32) (result i32)
    global.get 0
    global.set 1
    loop  ;; label = @1
      global.get 0
      local.get 0
      i32.load
      i32.load
      local.get 0
      i32.load
      i32.load
      call 1
      call 3
      global.get 0
      local.get 0
      i32.load
      i32.load
      call 1
      i32.add
      global.set 0
      global.get 0
      i32.const 61
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      global.get 0
      local.get 0
      i32.load
      i32.const 4
      i32.add
      i32.load
      i32.load
      local.get 0
      i32.load
      i32.const 4
      i32.add
      i32.load
      i32.load
      call 1
      call 3
      global.get 0
      local.get 0
      i32.load
      i32.const 4
      i32.add
      i32.load
      i32.load
      call 1
      i32.add
      global.set 0
      local.get 0
      i32.const 4
      i32.add
      i32.load
      local.set 0
      local.get 0
      if  ;; label = @2
        global.get 0
        i32.const 38
        i32.store8
        global.get 0
        i32.const 1
        i32.add
        global.set 0
      end
      local.get 0
      br_if 0 (;@1;)
    end
    global.get 0
    i32.const 0
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 1)
  (func (;7;) (type 1) (param i32) (result i32)
    local.get 0
    call 2)
  (memory (;0;) 2)
  (global (;0;) (mut i32) (i32.const 65536))
  (global (;1;) (mut i32) (i32.const 0))
  (export "memory" (memory 0))
  (export "url_encode_rfc3986" (func 4))
  (export "url_encode_www_form" (func 5))
  (export "url_encode_query_www_form" (func 6))
  (export "alloc" (func 7)))
