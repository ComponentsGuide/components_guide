(module
  (type (;0;) (func (result i32)))
  (type (;1;) (func (param i32 i32) (result i32)))
  (type (;2;) (func))
  (type (;3;) (func (param i32)))
  (type (;4;) (func (param i32) (result i32)))
  (type (;5;) (func (param i32 i32)))
  (import "datasource" "get_episodes_count" (func (;0;) (type 0)))
  (import "datasource" "write_episode_id" (func (;1;) (type 1)))
  (import "datasource" "write_episode_title" (func (;2;) (type 1)))
  (import "datasource" "write_episode_description" (func (;3;) (type 1)))
  (func (;4;) (type 4) (param i32) (result i32)
    (local i32)
    global.get 0
    global.get 0
    local.get 0
    i32.add
    global.set 0)
  (func (;5;) (type 2)
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
  (func (;6;) (type 0) (result i32)
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
  (func (;7;) (type 3) (param i32)
    (local i32 i32 i32)
    local.get 0
    global.get 1
    i32.eq
    if  ;; label = @1
      return
    end
    global.get 0
    local.set 3
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
    local.get 1
    local.set 2
    i32.const 0
    local.set 1
    loop  ;; label = @1
      local.get 1
      local.get 2
      i32.ne
      if  ;; label = @2
        local.get 1
        local.get 3
        i32.add
        local.get 0
        local.get 1
        i32.add
        i32.load8_u
        i32.store8
        local.get 1
        i32.const 1
        i32.add
        local.set 1
        br 1 (;@1;)
      end
    end
    global.get 0
    local.get 2
    i32.add
    global.set 0)
  (func (;8;) (type 3) (param i32)
    call 5
    i32.const 760
    call 7
    local.get 0
    call 7
    i32.const 763
    call 7
    call 6
    drop)
  (func (;9;) (type 5) (param i32 i32)
    call 5
    i32.const 766
    call 7
    local.get 0
    call 7
    i32.const 768
    call 7
    call 5
    i32.const 298
    call 7
    local.get 1
    call 7
    i32.const 308
    call 7
    call 6
    drop
    i32.const 760
    call 7
    local.get 0
    call 7
    i32.const 770
    call 7
    call 6
    drop)
  (func (;10;) (type 2)
    i32.const 65536
    global.set 0)
  (func (;11;) (type 2)
    (local i32 i32)
    call 0
    local.tee 1
    i32.eqz
    if  ;; label = @1
      return
    end
    loop  ;; label = @1
      call 5
      i32.const 265
      call 7
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 271
      call 7
      i32.const 277
      call 7
      i32.const 292
      call 7
      global.get 0
      i32.const 34
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 7
      global.get 0
      local.get 0
      global.get 0
      call 1
      i32.add
      global.set 0
      i32.const 308
      call 7
      i32.const 312
      call 8
      i32.const 317
      call 7
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 7
      global.get 0
      local.get 0
      global.get 0
      call 2
      i32.add
      global.set 0
      i32.const 308
      call 7
      i32.const 324
      call 8
      i32.const 330
      call 7
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 7
      global.get 0
      local.get 0
      global.get 0
      call 2
      i32.add
      global.set 0
      i32.const 308
      call 7
      i32.const 344
      call 8
      i32.const 357
      call 7
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 7
      global.get 0
      local.get 0
      global.get 0
      call 3
      i32.add
      global.set 0
      i32.const 308
      call 7
      i32.const 370
      call 8
      i32.const 382
      call 7
      global.get 0
      i32.const 62
      i32.store8
      global.get 0
      i32.const 1
      i32.add
      global.set 0
      i32.const 298
      call 7
      global.get 0
      local.get 0
      global.get 0
      call 3
      i32.add
      global.set 0
      i32.const 308
      call 7
      i32.const 399
      call 8
      i32.const 415
      call 8
      call 6
      drop
      local.get 0
      i32.const 1
      i32.add
      local.tee 0
      local.get 1
      i32.lt_s
      br_if 0 (;@1;)
    end)
  (func (;12;) (type 0) (result i32)
    call 5
    i32.const 420
    call 7
    i32.const 461
    call 7
    i32.const 466
    call 7
    i32.const 477
    call 7
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 481
    call 7
    i32.const 497
    call 7
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 540
    call 7
    i32.const 560
    call 7
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 608
    call 7
    i32.const 620
    call 7
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 653
    call 7
    i32.const 670
    call 7
    global.get 0
    i32.const 34
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    global.get 0
    i32.const 62
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 711
    call 7
    global.get 0
    i32.const 62
    i32.store8
    global.get 0
    i32.const 1
    i32.add
    global.set 0
    i32.const 324
    global.get 3
    call 9
    i32.const 370
    global.get 4
    call 9
    i32.const 399
    global.get 4
    call 9
    i32.const 720
    global.get 5
    call 9
    i32.const 734
    global.get 6
    call 9
    i32.const 739
    global.get 7
    call 9
    call 11
    i32.const 748
    call 8
    i32.const 756
    call 8
    call 6)
  (memory (;0;) 2)
  (global (;0;) (mut i32) (i32.const 65536))
  (global (;1;) (mut i32) (i32.const 0))
  (global (;2;) (mut i32) (i32.const 0))
  (global (;3;) (mut i32) (i32.const 255))
  (global (;4;) (mut i32) (i32.const 261))
  (global (;5;) (mut i32) (i32.const 261))
  (global (;6;) (mut i32) (i32.const 261))
  (global (;7;) (mut i32) (i32.const 262))
  (export "memory" (memory 0))
  (export "title" (global 3))
  (export "description" (global 4))
  (export "author" (global 5))
  (export "link" (global 6))
  (export "language" (global 7))
  (export "free_all" (func 10))
  (export "alloc" (func 4))
  (export "write_episodes_xml" (func 11))
  (export "text_xml" (func 12))
  (data (;0;) (i32.const 720) "itunes:author")
  (data (;1;) (i32.const 466) " version=\22")
  (data (;2;) (i32.const 357) "<description")
  (data (;3;) (i32.const 653) " xmlns:content=\22")
  (data (;4;) (i32.const 540) " xmlns:googleplay=\22")
  (data (;5;) (i32.const 298) "<![CDATA[")
  (data (;6;) (i32.const 312) "guid")
  (data (;7;) (i32.const 608) " xmlns:dc=\22")
  (data (;8;) (i32.const 760) "</")
  (data (;9;) (i32.const 255) "hello")
  (data (;10;) (i32.const 770) ">\0a")
  (data (;11;) (i32.const 748) "channel")
  (data (;12;) (i32.const 292) "false")
  (data (;13;) (i32.const 415) "item")
  (data (;14;) (i32.const 560) "http://www.google.com/schemas/play-podcasts/1.0")
  (data (;15;) (i32.const 324) "title")
  (data (;16;) (i32.const 317) "<title")
  (data (;17;) (i32.const 768) ">")
  (data (;18;) (i32.const 330) "<itunes:title")
  (data (;19;) (i32.const 734) "link")
  (data (;20;) (i32.const 481) " xmlns:itunes=\22")
  (data (;21;) (i32.const 344) "itunes:title")
  (data (;22;) (i32.const 766) "<")
  (data (;23;) (i32.const 620) "http://purl.org/dc/elements/1.1/")
  (data (;24;) (i32.const 497) "http://www.itunes.com/dtds/podcast-1.0.dtd")
  (data (;25;) (i32.const 370) "description")
  (data (;26;) (i32.const 382) "<itunes:subtitle")
  (data (;27;) (i32.const 711) "<channel")
  (data (;28;) (i32.const 477) "2.0")
  (data (;29;) (i32.const 739) "language")
  (data (;30;) (i32.const 461) "<rss")
  (data (;31;) (i32.const 262) "en")
  (data (;32;) (i32.const 756) "rss")
  (data (;33;) (i32.const 399) "itunes:subtitle")
  (data (;34;) (i32.const 265) "<item")
  (data (;35;) (i32.const 763) ">\0a")
  (data (;36;) (i32.const 271) "<guid")
  (data (;37;) (i32.const 670) "http://purl.org/rss/1.0/modules/content/")
  (data (;38;) (i32.const 277) " isPermaLink=\22")
  (data (;39;) (i32.const 420) "<?xml version=\221.0\22 encoding=\22UTF-8\22?>\0a")
  (data (;40;) (i32.const 308) "]]>"))
